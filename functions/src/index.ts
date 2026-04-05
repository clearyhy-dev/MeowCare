import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

setGlobalOptions({ region: "asia-east1", maxInstances: 10 });

admin.initializeApp();
const db = admin.firestore();

const SYSTEM_POST_AUTHORS = new Set([
  "meowcare_editorial",
  "reddit",
  "admin",
]);

async function bumpUnread(recipientUserId: string): Promise<void> {
  await db
    .collection("users")
    .doc(recipientUserId)
    .set({ notificationUnreadCount: admin.firestore.FieldValue.increment(1) }, { merge: true });
}

/** Unicode-safe truncation (counts code points, not UTF-16 units). */
function truncateText(s: string, maxChars: number): string {
  const t = (s ?? "").trim().replace(/\s+/g, " ");
  if (!t) return "";
  const chars = Array.from(t);
  if (chars.length <= maxChars) return t;
  return chars.slice(0, maxChars).join("") + "…";
}

async function getUserDisplayName(uid: string): Promise<string> {
  try {
    const snap = await db.collection("users").doc(uid).get();
    if (!snap.exists) return "Member";
    const d = snap.data()!;
    const n = (d.displayName as string) || (d.name as string) || "";
    return n.trim() || "Member";
  } catch {
    return "Member";
  }
}

async function insertNotification(params: {
  recipientUserId: string;
  type: string;
  actorUserId: string | null;
  actorDisplayName: string;
  targetPostId: string;
  targetCommentId: string | null;
  title: string;
  body: string;
}): Promise<void> {
  const ref = db.collection("notifications").doc();
  await ref.set({
    recipientUserId: params.recipientUserId,
    type: params.type,
    actorUserId: params.actorUserId,
    actorDisplayName: params.actorDisplayName,
    targetPostId: params.targetPostId,
    targetCommentId: params.targetCommentId,
    title: params.title,
    body: params.body,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await bumpUnread(params.recipientUserId);
}

export const onCommentCreated = onDocumentCreated("comments/{commentId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const c = snap.data();
  const commentAuthor = c.authorId as string;
  const postId = c.postId as string;
  const parentCommentId = (c.parentCommentId as string) || "";

  const postSnap = await db.collection("posts").doc(postId).get();
  if (!postSnap.exists) return;
  const post = postSnap.data()!;
  const postAuthor = (post.authorId as string) || "";

  if (parentCommentId) {
    const parentSnap = await db.collection("comments").doc(parentCommentId).get();
    if (!parentSnap.exists) return;
    const parentAuthor = (parentSnap.data()!.authorId as string) || "";
    if (parentAuthor && parentAuthor !== commentAuthor) {
      const name = (c.authorDisplayName as string) || "Someone";
      const postTitle = truncateText((post.title as string) || "", 60);
      const excerpt = truncateText((c.content as string) || "", 160);
      await insertNotification({
        recipientUserId: parentAuthor,
        type: "reply_to_comment",
        actorUserId: commentAuthor,
        actorDisplayName: name,
        targetPostId: postId,
        targetCommentId: snap.id,
        title: postTitle ? `Reply on 「${postTitle}」` : "New reply to your comment",
        body: excerpt ? `${name}: ${excerpt}` : `${name} replied to your comment.`,
      });
    }
    return;
  }

  if (
    postAuthor &&
    postAuthor !== commentAuthor &&
    !SYSTEM_POST_AUTHORS.has(postAuthor)
  ) {
    const name = (c.authorDisplayName as string) || "Someone";
    const postTitle = truncateText((post.title as string) || "", 60);
    const excerpt = truncateText((c.content as string) || "", 160);
    await insertNotification({
      recipientUserId: postAuthor,
      type: "comment_on_post",
      actorUserId: commentAuthor,
      actorDisplayName: name,
      targetPostId: postId,
      targetCommentId: snap.id,
      title: postTitle ? `Comment on 「${postTitle}」` : "New comment on your post",
      body: excerpt ? `${name}: ${excerpt}` : `${name} commented on your post.`,
    });
  }
});

export const onLikeWritten = onDocumentWritten("likes/{likeId}", async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;
  const d = after.data()!;
  if ((d.vote as number) !== 1) return;
  const before = event.data?.before;
  if (before?.exists && (before.data()?.vote as number) === 1) return;

  const postId = d.postId as string;
  const actorUid = d.uid as string;
  const postSnap = await db.collection("posts").doc(postId).get();
  if (!postSnap.exists) return;
  const post = postSnap.data()!;
  const postAuthor = (post.authorId as string) || "";
  if (!postAuthor || postAuthor === actorUid || SYSTEM_POST_AUTHORS.has(postAuthor)) return;

  const likerName = await getUserDisplayName(actorUid);
  const postTitle = truncateText((post.title as string) || "", 80);
  await insertNotification({
    recipientUserId: postAuthor,
    type: "post_liked",
    actorUserId: actorUid,
    actorDisplayName: likerName,
    targetPostId: postId,
    targetCommentId: null,
    title: postTitle ? `「${postTitle}」` : "Someone liked your post",
    body: postTitle
      ? `${likerName} liked your post.`
      : `${likerName} liked your post.`,
  });
});

export const markNotificationRead = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const notificationId = request.data?.notificationId as string;
  if (!notificationId) throw new HttpsError("invalid-argument", "notificationId required.");

  const ref = db.collection("notifications").doc(notificationId);
  const doc = await ref.get();
  if (!doc.exists) throw new HttpsError("not-found", "Notification not found.");
  const data = doc.data()!;
  if (data.recipientUserId !== uid) throw new HttpsError("permission-denied", "Not yours.");

  if (data.isRead === true) return { ok: true };

  const userRef = db.collection("users").doc(uid);
  // Firestore 要求：事务内所有 read 必须在任何 write 之前，否则事务失败。
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    if (!fresh.exists) return;
    const fd = fresh.data()!;
    if (fd.isRead === true) return;
    const us = await tx.get(userRef);
    const cur = (us.data()?.notificationUnreadCount as number) ?? 0;
    tx.update(ref, {
      isRead: true,
      readAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(userRef, { notificationUnreadCount: Math.max(0, cur - 1) }, { merge: true });
  });
  return { ok: true };
});

export const markAllNotificationsRead = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const qs = await db
    .collection("notifications")
    .where("recipientUserId", "==", uid)
    .where("isRead", "==", false)
    .limit(400)
    .get();

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (const d of qs.docs) {
    batch.update(d.ref, { isRead: true, readAt: now });
  }
  batch.set(db.collection("users").doc(uid), { notificationUnreadCount: 0 }, { merge: true });
  await batch.commit();
  return { ok: true, updated: qs.size };
});
