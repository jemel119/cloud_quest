import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

async function readMyQuestState(uid) {
  const db = getFirestore();
  const [challenge, progress] = await db.getAll(
    db.doc("challenges/today"),
    db.doc(`users/${uid}/progress/today`),
  );

  const title = challenge.data()?.title;
  const prompt = challenge.data()?.prompt;

  if (
    typeof title !== "string" ||
    !title.trim() ||
    typeof prompt !== "string" ||
    !prompt.trim()
  ) {
    throw new Error("Today's challenge is missing or incomplete.");
  }

  return {
    title: title.trim(),
    prompt: prompt.trim(),
    completed: progress.data()?.completed === true,
  };
}

export const askQuestCoach = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  let state;
  try {
    if (
      process.env.FUNCTIONS_EMULATOR === "true" &&
      request.data?.simulateToolFailure === true
    ) {
      throw new Error("Simulated quest state read failure.");
    }

    state = await readMyQuestState(request.auth.uid);
  } catch {
    throw new HttpsError(
      "unavailable",
      "The coach could not read your quest. Please try again.",
    );
  }

  const hint = state.completed
    ? `You already completed “${state.title}.” Think of one thing you learned from it.`
    : `For “${state.title},” focus on the first action in the prompt: ${state.prompt}`;

  return { hint };
});