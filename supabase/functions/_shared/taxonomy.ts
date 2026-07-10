// Fixed category taxonomy (PRD §9.3) — mirrored in Dart as PhraseCategory
// (lib/features/phrasebook/models/phrase.dart). Keep the two lists in sync.

export const CATEGORY_IDS = [
  "greetings_smalltalk",
  "food_dining",
  "shopping_money",
  "transport_directions",
  "housing_utilities",
  "health_emergencies",
  "work_school",
  "bureaucracy_documents",
  "social_relationships",
  "numbers_time_dates",
] as const;

export type CategoryId = (typeof CATEGORY_IDS)[number];

export const CATEGORY_DESCRIPTIONS: Record<CategoryId, string> = {
  greetings_smalltalk: "Greetings, introductions, pleasantries, casual small talk",
  food_dining: "Ordering food, restaurants, groceries, dietary needs",
  shopping_money: "Shopping, prices, payments, bargaining, currency",
  transport_directions: "Getting around: taxis, buses, trains, asking for directions",
  housing_utilities: "Renting, apartments, landlords, utilities, repairs",
  health_emergencies: "Doctors, pharmacies, symptoms, emergencies, insurance",
  work_school: "Work, meetings, colleagues, university, studying",
  bureaucracy_documents: "Government offices, visas, banking paperwork, forms, contracts",
  social_relationships: "Friends, family, dating, invitations, social plans",
  numbers_time_dates: "Numbers, telling time, dates, schedules, quantities",
};

// Mirrored in Dart as kTargetLanguages (lib/core/constants/languages.dart).
export const SUPPORTED_LANGS: Record<string, string> = {
  es: "Spanish",
  fr: "French",
  pt: "Portuguese",
  de: "German",
  it: "Italian",
  sw: "Swahili",
  yo: "Yoruba",
  ig: "Igbo",
  el: "Greek",
  ar: "Arabic",
  zh: "Chinese (Mandarin)",
  hi: "Hindi",
  ja: "Japanese",
  ko: "Korean",
  en: "English",
};
