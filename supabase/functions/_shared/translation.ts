// Shared Claude translation plumbing for translate-phrase and seed-phrasebook.

import Anthropic from "npm:@anthropic-ai/sdk@0.72.1";
import {
  CATEGORY_DESCRIPTIONS,
  CATEGORY_IDS,
  SUPPORTED_LANGS,
} from "./taxonomy.ts";

// Haiku keeps warm round-trips inside the PRD's <3s target at ~$0.002-0.004
// per translation. Bump to a Sonnet-tier model if QA shows weak register or
// grammar notes for low-resource target languages.
export const TRANSLATE_MODEL = "claude-haiku-4-5";

export interface TranslationPayload {
  translatedText: string;
  registerNote: string;
  vocabBreakdown: { term: string; meaning: string }[];
  grammarNote: string;
  pronunciation: { phonetic: string; ipa: string };
  category: string;
  confidence: "high" | "medium" | "low";
  confidenceNote: string | null;
}

export const translationSchema = {
  type: "object",
  properties: {
    translatedText: { type: "string" },
    registerNote: { type: "string" },
    vocabBreakdown: {
      type: "array",
      items: {
        type: "object",
        properties: {
          term: { type: "string" },
          meaning: { type: "string" },
        },
        required: ["term", "meaning"],
        additionalProperties: false,
      },
    },
    grammarNote: { type: "string" },
    pronunciation: {
      type: "object",
      properties: {
        phonetic: { type: "string" },
        ipa: { type: "string" },
      },
      required: ["phonetic", "ipa"],
      additionalProperties: false,
    },
    category: { type: "string", enum: [...CATEGORY_IDS] },
    confidence: { type: "string", enum: ["high", "medium", "low"] },
    confidenceNote: { anyOf: [{ type: "string" }, { type: "null" }] },
  },
  required: [
    "translatedText",
    "registerNote",
    "vocabBreakdown",
    "grammarNote",
    "pronunciation",
    "category",
    "confidence",
    "confidenceNote",
  ],
  additionalProperties: false,
} as const;

export function buildSystemPrompt(targetLang: string): string {
  const language = SUPPORTED_LANGS[targetLang];
  const taxonomy = CATEGORY_IDS
    .map((id) => `- ${id}: ${CATEGORY_DESCRIPTIONS[id]}`)
    .join("\n");

  return `You are an expert ${language} translator and language coach for people relocating abroad. Given an English sentence, produce:

- translatedText: the most natural way a native speaker would say it in ${language}. Prefer everyday phrasing over literal translation.
- registerNote: one sentence on formality and when to use it (e.g. "Neutral — fine with strangers; use the formal form in official settings").
- vocabBreakdown: the 2-6 most useful words or chunks from the translation, each with a short English meaning (include gender/part of speech where relevant).
- grammarNote: one or two sentences explaining the key grammatical structure, written for a beginner.
- pronunciation: phonetic = an intuitive English-friendly respelling with stressed syllables in CAPS; ipa = the IPA transcription.
- category: exactly one taxonomy id from the list below that best fits the sentence's real-world situation.
- confidence: "high" when you are sure the translation is natural and correct. Use "medium" or "low" when the input is ambiguous, idiomatic, or you are unsure of the natural rendering — and explain why in confidenceNote rather than guessing confidently. confidenceNote is null when confidence is "high".

Taxonomy:
${taxonomy}`;
}

export function getAnthropicClient(): Anthropic {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) throw new Error("ANTHROPIC_API_KEY secret is not set");
  return new Anthropic({ apiKey });
}

export async function translateOne(
  client: Anthropic,
  text: string,
  targetLang: string,
): Promise<TranslationPayload> {
  const response = await client.messages.create({
    model: TRANSLATE_MODEL,
    max_tokens: 1500,
    system: buildSystemPrompt(targetLang),
    output_config: {
      format: { type: "json_schema", schema: translationSchema },
    },
    messages: [{ role: "user", content: text }],
  });

  const block = response.content.find((b) => b.type === "text");
  if (!block || block.type !== "text") {
    throw new Error(`No text block in model response (stop_reason: ${response.stop_reason})`);
  }
  return JSON.parse(block.text) as TranslationPayload;
}

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
