import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();
const db = getFirestore();

export const completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  if (request.data?.challengeId !== "today") {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }

  const progressRef = db.doc(`users/${request.auth.uid}/progress/today`);
  const challengeRef = db.doc("challenges/today");

  return db.runTransaction(async (transaction) => {
    const progress = await transaction.get(progressRef);

    if (progress.exists) {
      const { completed, points, badgeId } = progress.data();
      return { completed, points, badgeId, alreadyCompleted: true };
    }

    const challenge = await transaction.get(challengeRef);
    if (!challenge.exists) {
      throw new HttpsError("failed-precondition", "Today's challenge is unavailable.");
    }

    const reward = { completed: true, points: 10, badgeId: "first-quest" };

    transaction.set(progressRef, {
      ...reward,
      completedAt: FieldValue.serverTimestamp(),
    });

    return { ...reward, alreadyCompleted: false };
  });
});
export { askQuestCoach } from "./questCoach.js";