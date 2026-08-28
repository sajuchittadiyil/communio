import {
  handledAskCommunioIntents,
  interpretAskCommunioQuestion,
} from "./intent_interpreter.ts";
import type {
  AskCommunioIntent,
  AskCommunioInterpretation,
} from "./intent_interpreter.ts";

type Case = {
  question: string;
  expected: Partial<AskCommunioInterpretation> & { intent: AskCommunioIntent };
};

function assertEquals(
  actual: unknown,
  expected: unknown,
  message: string,
): void {
  if (Object.is(actual, expected)) return;
  throw new Error(
    `${message}: expected ${JSON.stringify(expected)}, got ${
      JSON.stringify(actual)
    }`,
  );
}

function cases(category: string, entries: Case[]): void {
  Deno.test(category, () => {
    for (const { question, expected } of entries) {
      const actual = interpretAskCommunioQuestion(question);
      for (const [key, value] of Object.entries(expected)) {
        assertEquals(
          actual[key as keyof AskCommunioInterpretation],
          value,
          `${question} (${key})`,
        );
      }
    }
  });
}

const decisionCases: Case[] = [
  "Who should become the next Principal?",
  "Who should be appointed Principal?",
  "Who is the best candidate for Principal?",
  "Who is the best successor to the current Principal?",
  "Who should replace the current Principal?",
  "Rank the candidates for Principal.",
  "Recommend someone for Provincial.",
  "Who would make the best Community Superior?",
].map((question) => ({
  question,
  expected: {
    intent: "decision_boundary",
    topic: "appointment_recommendation",
  },
}));
decisionCases.push(
  {
    question: "Who is eligible to become School Principal?",
    expected: { intent: "eligibility_search", role: "principal" },
  },
  {
    question: "Show members eligible for Principal.",
    expected: { intent: "eligibility_search", role: "principal" },
  },
  {
    question: "Is Fr. Joseph eligible for Novice Master?",
    expected: { intent: "eligibility_search", role: "novice_master" },
  },
  {
    question: "Who meets the eligibility rules for Chaplain?",
    expected: { intent: "eligibility_search", role: "chaplain" },
  },
);
cases("decision boundary precedes factual eligibility", decisionCases);

cases("origin and current location remain distinct", [
  {
    question: "How many members are from Kerala?",
    expected: { intent: "member_origin_search", entity: "Kerala" },
  },
  {
    question: "Show members from Kerala.",
    expected: { intent: "member_origin_search", entity: "Kerala" },
  },
  {
    question: "Who is from Odisha?",
    expected: { intent: "member_origin_search", entity: "Odisha" },
  },
  {
    question: "Which members come from Sundargarh district?",
    expected: {
      intent: "member_origin_search",
      entity: "Sundargarh",
      originField: "district",
    },
  },
  {
    question: "Who belongs to the Diocese of Rourkela?",
    expected: {
      intent: "member_origin_search",
      entity: "Rourkela",
      originField: "native_diocese",
    },
  },
  {
    question: "Who is from St. Joseph Parish?",
    expected: {
      intent: "member_origin_search",
      entity: "St. Joseph",
      originField: "native_parish",
    },
  },
  {
    question: "Who is currently serving in Kerala?",
    expected: { intent: "current_location_search", entity: "Kerala" },
  },
  {
    question: "How many members are serving in Odisha now?",
    expected: { intent: "current_location_search", entity: "Odisha" },
  },
  {
    question: "Who is presently assigned in Karnataka?",
    expected: { intent: "current_location_search", entity: "Karnataka" },
  },
  {
    question: "Which members are currently outside India?",
    expected: {
      intent: "current_location_search",
      entity: "India",
      topic: "outside",
    },
  },
]);

cases("AC-024 member languages", [
  {
    question: "what languages does Joseph Varghese speak",
    expected: {
      intent: "member_languages",
      entity: "Joseph Varghese",
      topic: "spoken",
    },
  },
  {
    question: "Which languages does Joseph Varghese know?",
    expected: {
      intent: "member_languages",
      entity: "Joseph Varghese",
      topic: "recorded",
    },
  },
  {
    question: "Languages of Joseph Varghese",
    expected: {
      intent: "member_languages",
      entity: "Joseph Varghese",
      topic: "recorded",
    },
  },
]);

cases("AC-088 and AC-089 community lifecycle", [
  {
    question: "communities opened in 2015",
    expected: { intent: "community_lifecycle", topic: "OPENED", year: 2015 },
  },
  {
    question: "Which communities established in 2015?",
    expected: { intent: "community_lifecycle", topic: "OPENED", year: 2015 },
  },
  {
    question: "communities closed in 2015",
    expected: { intent: "community_lifecycle", topic: "CLOSED", year: 2015 },
  },
]);

cases("AC-090 formal transfer", [
  {
    question: "who transferred from St Antony Community in 2015",
    expected: {
      intent: "formal_transfer",
      entity: "St Antony Community",
      topic: "from_community",
      year: 2015,
    },
  },
  {
    question: "Who formally moved from St Antony Community in 2015?",
    expected: {
      intent: "formal_transfer",
      entity: "St Antony Community",
      year: 2015,
    },
  },
  {
    question: "when was Joseph Varghese transferred",
    expected: {
      intent: "formal_transfer",
      entity: "Joseph Varghese",
      topic: "member_history",
    },
  },
  {
    question:
      "when was Joseph Varghese transferred from one community to another",
    expected: {
      intent: "formal_transfer",
      entity: "Joseph Varghese",
      topic: "member_history",
    },
  },
  {
    question: "show the transfer history of Joseph Varghese",
    expected: {
      intent: "formal_transfer",
      entity: "Joseph Varghese",
      topic: "member_history",
    },
  },
  {
    question: "why was Joseph Varghese transferred",
    expected: {
      intent: "formal_transfer",
      entity: "Joseph Varghese",
      topic: "member_reason",
    },
  },
  {
    question: "show the transfer history of Antony Antony",
    expected: {
      intent: "formal_transfer",
      entity: "Antony Antony",
      topic: "member_history",
    },
  },
]);

cases("natural Provincial analytics families", [
  {
    question: "How many parishes",
    expected: {
      intent: "ministry_directory",
      topic: "parish",
      outputType: "count",
    },
  },
  {
    question: "count the hospitals",
    expected: {
      intent: "ministry_directory",
      topic: "hospital",
      outputType: "count",
    },
  },
  {
    question: "How many members between 55 years old to 60 years old",
    expected: { intent: "age_search", age: 55, ageTo: 60, outputType: "count" },
  },
  {
    question: "members aged 55–60",
    expected: { intent: "age_search", age: 55, ageTo: 60 },
  },
  {
    question: "how many birthdays in the month of september",
    expected: { intent: "birthday_month", month: 9, outputType: "count" },
  },
  {
    question: "Who has a birthday in September?",
    expected: { intent: "birthday_month", month: 9 },
  },
  {
    question:
      "How many members will have their 10th year first vows anniversary next year",
    expected: {
      intent: "vocation_anniversary",
      anniversary: 10,
      topic: "FIRST_PROFESSION",
      outputType: "count",
    },
  },
  {
    question: "25th temporary vows anniversary in 2030",
    expected: {
      intent: "vocation_anniversary",
      anniversary: 25,
      year: 2030,
      topic: "FIRST_PROFESSION",
    },
  },
]);

cases("location entities are not member origins", [
  {
    question: "Which communities are in Kerala?",
    expected: {
      intent: "location_entity_search",
      topic: "communities",
      entity: "Kerala",
    },
  },
  {
    question: "Show ministries in Odisha.",
    expected: {
      intent: "location_entity_search",
      topic: "ministries",
      entity: "Odisha",
    },
  },
  {
    question: "Which communities are in Karnataka?",
    expected: { intent: "location_entity_search", entity: "Karnataka" },
  },
  {
    question: "What ministries are outside India?",
    expected: {
      intent: "location_entity_search",
      entity: "India",
      role: "outside",
    },
  },
  {
    question: "Show communities in Bengaluru.",
    expected: { intent: "location_entity_search", entity: "Bengaluru" },
  },
]);

cases("member history and focused milestones", [
  {
    question: "Where has Fr. Thomas served?",
    expected: { intent: "member_history", entity: "Thomas", topic: "ministry" },
  },
  {
    question: "Give me Fr. Thomas's history.",
    expected: { intent: "member_history", entity: "Thomas" },
  },
  {
    question: "Show Fr. Thomas's ministry history.",
    expected: { intent: "member_history", entity: "Thomas", topic: "ministry" },
  },
  {
    question: "What communities has Fr. Thomas lived in?",
    expected: {
      intent: "member_history",
      entity: "Thomas",
      topic: "community",
    },
  },
  {
    question: "What offices has Fr. Thomas held?",
    expected: { intent: "member_appointment_history", entity: "Thomas" },
  },
  {
    question: "Did Fr. Thomas ever take a sabbatical?",
    expected: { intent: "member_history", entity: "Thomas", topic: "leave" },
  },
  {
    question: "When was Fr. Thomas ordained?",
    expected: {
      intent: "member_history",
      entity: "Thomas",
      topic: "ordination",
    },
  },
  {
    question: "When did Fr. Thomas make first profession?",
    expected: {
      intent: "member_history",
      entity: "Thomas",
      topic: "first_profession",
    },
  },
  {
    question: "Where did Fr. Thomas serve as Principal?",
    expected: {
      intent: "member_history",
      entity: "Thomas",
      topic: "principal",
    },
  },
  {
    question: "Ministry history of Joseph Varghese",
    expected: {
      intent: "member_history",
      entity: "Joseph Varghese",
      topic: "ministry",
    },
  },
  {
    question: "Show ministry history of Fr. Thomas Mathew",
    expected: {
      intent: "member_history",
      entity: "Thomas Mathew",
      topic: "ministry",
    },
  },
]);

cases("member-scoped appointment and location routing", [
  {
    question: "show the appointment history of Joseph Varghese",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
  {
    question: "appointment history Joseph Varghese",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
  {
    question: "where is Joseph Varghese now",
    expected: { intent: "member_current_location", entity: "Joseph Varghese" },
  },
  {
    question: "where is Joseph Varghese",
    expected: { intent: "member_current_location", entity: "Joseph Varghese" },
  },
  {
    question: "where is Fr. Joseph Varghese assigned",
    expected: { intent: "member_current_location", entity: "Joseph Varghese" },
  },
  {
    question: "where was Joseph Varghese in 2010",
    expected: {
      intent: "member_historical_location",
      entity: "Joseph Varghese",
      year: 2010,
    },
  },
  {
    question: "which community was Joseph Varghese in during 2010",
    expected: {
      intent: "member_historical_location",
      entity: "Joseph Varghese",
      year: 2010,
    },
  },
  {
    question: "what appointments has Joseph Varghese held",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
  {
    question: "what appointments did Joseph Varghese hold",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
  {
    question: "appointments held by Joseph Varghese",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
  {
    question: "what offices did Joseph Varghese hold",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
  {
    question: "what offices has Joseph Varghese held",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
  {
    question: "offices held by Joseph Varghese",
    expected: {
      intent: "member_appointment_history",
      entity: "Joseph Varghese",
    },
  },
]);

cases("member profile and title normalization", [
  {
    question: "What is Fr. Thomas Mathew's Religious ID?",
    expected: {
      intent: "member_profile",
      entity: "Thomas Mathew",
      topic: "religious_id",
    },
  },
  {
    question: "What qualifications does Father Thomas Mathew have?",
    expected: {
      intent: "member_profile",
      entity: "Thomas Mathew",
      topic: "qualifications",
    },
  },
  {
    question: "Where did Fr. Thomas study?",
    expected: {
      intent: "member_profile",
      entity: "Thomas",
      topic: "qualifications",
    },
  },
  {
    question: "What is Fr. Thomas's home parish?",
    expected: { intent: "member_profile", entity: "Thomas", topic: "origin" },
  },
  {
    question: "Which diocese is Bro. Joseph from?",
    expected: { intent: "member_profile", entity: "Joseph", topic: "origin" },
  },
  {
    question: "Which state is Brother Joseph from?",
    expected: { intent: "member_profile", entity: "Joseph", topic: "origin" },
  },
  {
    question: "Who are Fr. Thomas's parents?",
    expected: { intent: "member_profile", entity: "Thomas", topic: "parents" },
  },
  {
    question: "Where is Joseph Varghese from?",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "origin",
    },
  },
  {
    question: "Where is Fr. Thomas Mathew from?",
    expected: {
      intent: "member_profile",
      entity: "Thomas Mathew",
      topic: "origin",
    },
  },
  {
    question: "Which community is Joseph Varghese in?",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "current_assignment",
    },
  },
  {
    question: "Which ministry is Joseph Varghese in?",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "current_assignment",
    },
  },
  {
    question: "Profile of Joseph Varghese",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "profile",
    },
  },
  {
    question: "What is Joseph Varghese's date of birth?",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "date_of_birth",
    },
  },
  {
    question: "When was Joseph Varghese born?",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "date_of_birth",
    },
  },
  {
    question: "How old is Joseph Varghese?",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "age",
    },
  },
  {
    question: "Show Joseph Varghese's status",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "status",
    },
  },
]);

cases("Wave 1 community directory and profile routing", [
  {
    question: "list all communities",
    expected: {
      intent: "community_directory",
      topic: "active",
      outputType: "records",
    },
  },
  {
    question: "show communities",
    expected: { intent: "community_directory", topic: "active" },
  },
  {
    question: "community directory",
    expected: { intent: "community_directory", topic: "active" },
  },
  {
    question: "where is St Antony Community",
    expected: { intent: "community_profile", entity: "St Antony Community" },
  },
  {
    question: "show St Antony Community",
    expected: { intent: "community_profile", entity: "St Antony Community" },
  },
  {
    question: "tell me about St Antony Community",
    expected: { intent: "community_profile", entity: "St Antony Community" },
  },
]);

cases("Wave 1 ministry directory and profile routing", [
  {
    question: "how many ministries are there",
    expected: {
      intent: "ministry_directory",
      topic: "all",
      outputType: "count",
    },
  },
  {
    question: "list all ministries",
    expected: { intent: "ministry_directory", topic: "all" },
  },
  {
    question: "show ministries",
    expected: { intent: "ministry_directory", topic: "all" },
  },
  {
    question: "list schools",
    expected: { intent: "ministry_directory", topic: "school" },
  },
  {
    question: "show parishes",
    expected: { intent: "ministry_directory", topic: "parish" },
  },
  {
    question: "list hospitals",
    expected: { intent: "ministry_directory", topic: "hospital" },
  },
  {
    question: "show formation houses",
    expected: { intent: "ministry_directory", topic: "formation_house" },
  },
  {
    question: "show active schools",
    expected: { intent: "ministry_directory", topic: "school" },
  },
  {
    question: "where is St Antony School",
    expected: { intent: "ministry_profile", entity: "St Antony School" },
  },
  {
    question: "tell me about St Antony School",
    expected: { intent: "ministry_profile", entity: "St Antony School" },
  },
  {
    question: "location of St Antony School",
    expected: { intent: "ministry_profile", entity: "St Antony School" },
  },
  {
    question: "tell me about St. Joseph School",
    expected: { intent: "ministry_profile", entity: "St. Joseph School" },
  },
  {
    question: "tell me about St. Joseph School - Rourkela",
    expected: {
      intent: "ministry_profile",
      entity: "St. Joseph School - Rourkela",
    },
  },
  {
    question: "tell me about St Joseph School Rourkela",
    expected: {
      intent: "ministry_profile",
      entity: "St Joseph School Rourkela",
    },
  },
  {
    question: "tell me about St Joseph School in Rourkela",
    expected: {
      intent: "ministry_profile",
      entity: "St Joseph School in Rourkela",
    },
  },
  {
    question: "where is St Joseph School Rourkela",
    expected: {
      intent: "ministry_profile",
      entity: "St Joseph School Rourkela",
    },
  },
]);

cases("historical community routing", [
  {
    question: "Who were the community members of St. Antony Community in 2015?",
    expected: {
      intent: "community_membership_history",
      entity: "St. Antony Community",
      year: 2015,
      outputType: "records",
    },
  },
  {
    question: "members of St Antony Community in 2015",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony Community",
      year: 2015,
    },
  },
  {
    question: "who was in St Antony Community in 2015",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony Community",
      year: 2015,
    },
  },
  {
    question: "COMMUNITY MEMBERS ST ANTONY 2015",
    expected: {
      intent: "community_membership_history",
      entity: "ST ANTONY",
      year: 2015,
    },
  },
  {
    question: "members St Antony community 2015",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony community",
      year: 2015,
    },
  },
  {
    question: "Who lived in St. Antony Community in 1995?",
    expected: {
      intent: "community_membership_history",
      entity: "St. Antony Community",
      year: 1995,
    },
  },
  {
    question: "Who were the members of St. Antony Community in 2000?",
    expected: {
      intent: "community_membership_history",
      entity: "St. Antony Community",
      year: 2000,
    },
  },
  {
    question: "How many members were in St. Antony Community in 1998?",
    expected: {
      intent: "community_membership_history",
      entity: "St. Antony Community",
      year: 1998,
    },
  },
  {
    question: "Which members have lived in St. Antony Community?",
    expected: {
      intent: "community_membership_history",
      entity: "St. Antony Community",
    },
  },
  {
    question: "Who was Superior of St. Antony Community in 2005?",
    expected: {
      intent: "community_superior_history",
      entity: "St. Antony Community",
      year: 2005,
    },
  },
  {
    question: "who was the superior of St. Antony Community in 2015",
    expected: {
      intent: "community_superior_history",
      entity: "St. Antony Community",
      year: 2015,
    },
  },
  {
    question: "who was superior of St Antony Community Kolkata in 2015",
    expected: {
      intent: "community_superior_history",
      entity: "St Antony Community Kolkata",
      year: 2015,
    },
  },
  {
    question: "who lived in St Antony Community kolkota in 2015",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony Community kolkota",
      year: 2015,
    },
  },
  {
    question: "Who were the Superiors of St. Antony Community?",
    expected: {
      intent: "community_superior_history",
      entity: "St. Antony Community",
    },
  },
  {
    question: "Show the Superior history of St. Antony Community.",
    expected: {
      intent: "community_superior_history",
      entity: "St. Antony Community",
    },
  },
  {
    question: "Who lives in St Antony Community Kolkata?",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony Community Kolkata",
    },
  },
  {
    question: "Who currently lives in St Antony Community Kolkata?",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony Community Kolkata",
    },
  },
  {
    question: "How many members are in St Antony Community Kolkata?",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony Community Kolkata",
      outputType: "count",
    },
  },
  {
    question: "Count the members in St Antony Community Kolkata.",
    expected: {
      intent: "community_membership_history",
      entity: "St Antony Community Kolkata",
      outputType: "count",
    },
  },
  {
    question: "Who leads St Antony Community Kolkata?",
    expected: {
      intent: "community_superior_history",
      entity: "St Antony Community Kolkata",
    },
  },
  {
    question: "Who heads St Antony Community Kolkata?",
    expected: {
      intent: "community_superior_history",
      entity: "St Antony Community Kolkata",
    },
  },
]);

cases("historical ministry routing", [
  {
    question: "Who served at St. Antony School?",
    expected: {
      intent: "ministry_assignment_history",
      entity: "St. Antony School",
    },
  },
  {
    question: "Which members worked at St. Antony School?",
    expected: {
      intent: "ministry_assignment_history",
      entity: "St. Antony School",
    },
  },
  // Member-specific wording takes precedence so the member timeline, not a ministry-name lookup, answers it.
  {
    question: "What ministries has Fr. Thomas worked in?",
    expected: { intent: "member_history", entity: "Thomas", topic: "ministry" },
  },
  {
    question: "Who were the Principals of St. Antony School?",
    expected: {
      intent: "ministry_leadership_history",
      entity: "St. Antony School",
      role: "principal",
    },
  },
  {
    question: "Who was Principal of St. Antony School in 2005?",
    expected: {
      intent: "ministry_leadership_history",
      entity: "St. Antony School",
      role: "principal",
      year: 2005,
    },
  },
  {
    question: "Show Principal history for St. Antony School.",
    expected: {
      intent: "ministry_leadership_history",
      entity: "St. Antony School",
      role: "principal",
    },
  },
  {
    question: "Who works at St Antony School?",
    expected: {
      intent: "ministry_assignment_history",
      entity: "St Antony School",
    },
  },
  {
    question: "Who currently works at St Antony School?",
    expected: {
      intent: "ministry_assignment_history",
      entity: "St Antony School",
    },
  },
  {
    question: "Who is assigned to St Antony School?",
    expected: {
      intent: "ministry_assignment_history",
      entity: "St Antony School",
    },
  },
  {
    question: "Show members assigned to St Antony School.",
    expected: {
      intent: "ministry_assignment_history",
      entity: "St Antony School",
    },
  },
]);

cases("member-safe deterministic facts", [
  {
    question: "Who is the principal of Budakata School?",
    expected: {
      intent: "member_safe_factual",
      topic: "ministry_leader",
      entity: "Budakata School",
      role: "principal",
    },
  },
  {
    question: "Who is principal at Budakata School?",
    expected: {
      intent: "member_safe_factual",
      entity: "Budakata School",
      role: "principal",
    },
  },
  {
    question: "Budakata School principal",
    expected: {
      intent: "member_safe_factual",
      entity: "Budakata School",
      role: "principal",
    },
  },
  {
    question: "Who is the parish priest of Sacred Heart Parish?",
    expected: {
      intent: "member_safe_factual",
      entity: "Sacred Heart Parish",
      role: "parish_priest",
    },
  },
  {
    question: "Who is the superior of Sacred Heart Community?",
    expected: {
      intent: "member_safe_factual",
      topic: "community_superior",
      entity: "Sacred Heart Community",
    },
  },
  {
    question: "Who are the members of Sacred Heart Community?",
    expected: {
      intent: "member_safe_factual",
      topic: "community_members",
      entity: "Sacred Heart Community",
    },
  },
]);

cases("vocation cohorts preserve milestone and year range", [
  {
    question: "Who made final vows in 2020?",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 2020,
      outputType: "records",
    },
  },
  {
    question: "How many people made final vows in 2020?",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 2020,
      outputType: "count",
    },
  },
  {
    question: "who made final profession 2020",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 2020,
    },
  },
  {
    question: "who made final profession in 2020",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 2020,
    },
  },
  {
    question: "who made perpetual profession in 2020",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 2020,
    },
  },
  {
    question: "how many final professions were there in 2020",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 2020,
      outputType: "count",
    },
  },
  {
    question: "List perpetual vows during 2020",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 2020,
      outputType: "records",
    },
  },
  {
    question: "who made first profession in 1995",
    expected: {
      intent: "profession_cohort",
      year: 1995,
      outputType: "records",
    },
  },
  {
    question: "how many were ordained in 2010",
    expected: { intent: "ordination_cohort", year: 2010, outputType: "count" },
  },
  {
    question: "who were ordained in 2010",
    expected: {
      intent: "ordination_cohort",
      year: 2010,
      outputType: "records",
    },
  },
  {
    question: "how many people made first profession in 1995",
    expected: { intent: "profession_cohort", year: 1995, outputType: "count" },
  },
  {
    question: "Who joined the congregation in 1985?",
    expected: { intent: "vocation_cohort", topic: "JOINING", year: 1985 },
  },
  {
    question: "Who made first profession in 1990?",
    expected: { intent: "profession_cohort", year: 1990 },
  },
  {
    question: "temporary vows in 1995",
    expected: {
      intent: "profession_cohort",
      year: 1995,
      outputType: "records",
    },
  },
  {
    question: "temporary profession in 1995",
    expected: {
      intent: "profession_cohort",
      year: 1995,
      outputType: "records",
    },
  },
  {
    question: "who made temporary vows in 1995",
    expected: {
      intent: "profession_cohort",
      year: 1995,
      outputType: "records",
    },
  },
  {
    question: "how many made temporary profession in 1995",
    expected: { intent: "profession_cohort", year: 1995, outputType: "count" },
  },
  {
    question: "Who made final profession in 1995?",
    expected: {
      intent: "vocation_cohort",
      topic: "FINAL_PROFESSION",
      year: 1995,
    },
  },
  {
    question: "Who was ordained in 2000?",
    expected: { intent: "ordination_cohort", year: 2000 },
  },
  {
    question: "Who was ordained between 1995 and 2005?",
    expected: { intent: "ordination_cohort", year: 1995, yearTo: 2005 },
  },
]);

cases("present state and named appointments", [
  {
    question: "how many members are there now",
    expected: {
      intent: "present_state",
      topic: "active_members",
      outputType: "count",
    },
  },
  {
    question: "how many religious are there",
    expected: {
      intent: "present_state",
      topic: "active_members",
      outputType: "count",
    },
  },
  {
    question: "total members",
    expected: {
      intent: "present_state",
      topic: "active_members",
      outputType: "count",
    },
  },
  {
    question: "how many communities are there",
    expected: {
      intent: "present_state",
      topic: "active_communities",
      outputType: "count",
    },
  },
  {
    question: "total communities",
    expected: {
      intent: "present_state",
      topic: "active_communities",
      outputType: "count",
    },
  },
  {
    question: "How many active members do we have?",
    expected: { intent: "present_state", topic: "active_members" },
  },
  {
    question: "How many active communities are there?",
    expected: { intent: "present_state", topic: "active_communities" },
  },
  {
    question: "How many ministries are active?",
    expected: { intent: "present_state", topic: "active_ministries" },
  },
  {
    question: "Who are the current Community Superiors?",
    expected: { intent: "present_state", topic: "community_superiors" },
  },
  {
    question: "Who are the current Principals?",
    expected: { intent: "present_state", topic: "principals" },
  },
  {
    question: "Who is currently on leave?",
    expected: { intent: "present_state", topic: "on_leave" },
  },
  {
    question: "Who is retired?",
    expected: { intent: "present_state", topic: "retired" },
  },
  {
    question: "Which members are currently in formation?",
    expected: { intent: "present_state", topic: "formation" },
  },
  {
    question: "Who is the current Provincial?",
    expected: { intent: "appointment_search", entity: "provincial" },
  },
  {
    question: "who is provincial",
    expected: { intent: "appointment_search", entity: "provincial" },
  },
  {
    question: "who is the provincial",
    expected: { intent: "appointment_search", entity: "provincial" },
  },
  {
    question: "Who is the Provincial Secretary?",
    expected: { intent: "appointment_search", entity: "provincial_secretary" },
  },
  {
    question: "Who is the current Novice Master?",
    expected: { intent: "appointment_search", entity: "novice_master" },
  },
  {
    question: "Who is Assistant Provincial?",
    expected: { intent: "appointment_search", entity: "assistant_provincial" },
  },
  {
    question: "Who is the Assistant Provincial?",
    expected: { intent: "appointment_search", entity: "assistant_provincial" },
  },
  {
    question: "Current Assistant Provincial",
    expected: { intent: "appointment_search", entity: "assistant_provincial" },
  },
  {
    question: "Who is Bursar?",
    expected: { intent: "appointment_search", entity: "provincial_bursar" },
  },
  {
    question: "Who is Provincial Treasurer?",
    expected: { intent: "appointment_search", entity: "provincial_bursar" },
  },
]);

cases("Wave 1 leadership history and canonical member category counts", [
  {
    question: "list past provincials",
    expected: { intent: "leadership_history", role: "provincial" },
  },
  {
    question: "former provincials",
    expected: { intent: "leadership_history", role: "provincial" },
  },
  {
    question: "history of provincials",
    expected: { intent: "leadership_history", role: "provincial" },
  },
  {
    question: "who have served as provincial",
    expected: { intent: "leadership_history", role: "provincial" },
  },
  {
    question: "how many priests",
    expected: {
      intent: "present_state",
      topic: "priests",
      outputType: "count",
    },
  },
  {
    question: "number of priests",
    expected: {
      intent: "present_state",
      topic: "priests",
      outputType: "count",
    },
  },
  {
    question: "how many brothers",
    expected: {
      intent: "present_state",
      topic: "brothers",
      outputType: "count",
    },
  },
]);

cases("Wave 2 historical, staffing, tenure, and appointment routing", [
  {
    question: "list closed communities",
    expected: { intent: "community_directory", topic: "closed" },
  },
  {
    question: "community membership in 2010",
    expected: {
      intent: "clarification_needed",
      topic: "community_reference",
      year: 2010,
    },
  },
  {
    question: "members between 2010 and 2015",
    expected: { intent: "clarification_needed", year: 2010, yearTo: 2015 },
  },
  {
    question: "who joined the community in 2015",
    expected: { intent: "clarification_needed", year: 2015 },
  },
  {
    question: "who joined St Antony Community in 2015",
    expected: { intent: "community_movement", topic: "joined", year: 2015 },
  },
  {
    question: "who left St Antony Community in 2015",
    expected: { intent: "community_movement", topic: "left", year: 2015 },
  },
  {
    question: "history of St Antony Community",
    expected: { intent: "community_history", entity: "St Antony Community" },
  },
  {
    question: "which was the largest community in 2015",
    expected: { intent: "historical_community_ranking", year: 2015 },
  },
  {
    question: "members working in schools",
    expected: { intent: "ministry_type_staffing", topic: "school" },
  },
  {
    question: "how many members are in education ministry",
    expected: { intent: "ministry_type_staffing", outputType: "count" },
  },
  {
    question: "who worked at Morning Star School in 2015",
    expected: {
      intent: "ministry_assignment_history",
      entity: "Morning Star School",
      year: 2015,
    },
  },
  {
    question: "how many members work at Morning Star School",
    expected: {
      intent: "ministry_assignment_history",
      entity: "Morning Star School",
      outputType: "count",
      topic: "current",
    },
  },
  {
    question: "who succeeded Thomas Mathew",
    expected: { intent: "leadership_successor", entity: "Thomas Mathew" },
  },
  {
    question: "how long did Joseph Varghese serve as Provincial",
    expected: {
      intent: "member_office_tenure",
      entity: "Joseph Varghese",
      role: "provincial",
    },
  },
  {
    question: "previous assignment of Joseph Varghese",
    expected: { intent: "previous_assignment", entity: "Joseph Varghese" },
  },
  {
    question: "when was Joseph Varghese provincial",
    expected: { intent: "member_office_tenure", entity: "Joseph Varghese" },
  },
  {
    question: "appointments before 2010",
    expected: {
      intent: "appointment_period_search",
      year: 2010,
      timeRelation: "before",
    },
  },
  {
    question: "appointments after 2020",
    expected: {
      intent: "appointment_period_search",
      year: 2020,
      timeRelation: "after",
    },
  },
  {
    question: "compare appointments of Joseph and Francis",
    expected: {
      intent: "member_appointment_comparison",
      entity: "Joseph|Francis",
    },
  },
]);

cases("community size ranking and member age extremes", [
  {
    question: "which community has the most members",
    expected: { intent: "community_size_ranking", topic: "largest" },
  },
  {
    question: "which community has the most number",
    expected: { intent: "community_size_ranking", topic: "largest" },
  },
  {
    question: "which community has the highest number",
    expected: { intent: "community_size_ranking", topic: "largest" },
  },
  {
    question: "largest community",
    expected: { intent: "community_size_ranking", topic: "largest" },
  },
  {
    question: "which is the largest community",
    expected: { intent: "community_size_ranking", topic: "largest" },
  },
  {
    question: "biggest community",
    expected: { intent: "community_size_ranking", topic: "largest" },
  },
  {
    question: "community with maximum members",
    expected: { intent: "community_size_ranking", topic: "largest" },
  },
  {
    question: "which community has the fewest members",
    expected: { intent: "community_size_ranking", topic: "smallest" },
  },
  {
    question: "which community has the least number",
    expected: { intent: "community_size_ranking", topic: "smallest" },
  },
  {
    question: "smallest community",
    expected: { intent: "community_size_ranking", topic: "smallest" },
  },
  {
    question: "which is the smallest community",
    expected: { intent: "community_size_ranking", topic: "smallest" },
  },
  {
    question: "community with minimum members",
    expected: { intent: "community_size_ranking", topic: "smallest" },
  },
  {
    question: "who is the oldest member",
    expected: { intent: "member_age_extreme", topic: "oldest" },
  },
  {
    question: "who is the oldest",
    expected: { intent: "member_age_extreme", topic: "oldest" },
  },
  {
    question: "who is oldest",
    expected: { intent: "member_age_extreme", topic: "oldest" },
  },
  {
    question: "oldest",
    expected: { intent: "member_age_extreme", topic: "oldest" },
  },
  {
    question: "who is the eldest",
    expected: { intent: "member_age_extreme", topic: "oldest" },
  },
  {
    question: "who is the eldest member",
    expected: { intent: "member_age_extreme", topic: "oldest" },
  },
  {
    question: "who is the oldest religious",
    expected: { intent: "member_age_extreme", topic: "oldest" },
  },
  {
    question: "who is the youngest member",
    expected: { intent: "member_age_extreme", topic: "youngest" },
  },
  {
    question: "who is the youngest",
    expected: { intent: "member_age_extreme", topic: "youngest" },
  },
  {
    question: "who is youngest",
    expected: { intent: "member_age_extreme", topic: "youngest" },
  },
  {
    question: "youngest",
    expected: { intent: "member_age_extreme", topic: "youngest" },
  },
  {
    question: "who is the youngest religious",
    expected: { intent: "member_age_extreme", topic: "youngest" },
  },
]);

cases("composed community queries preserve outer intent", [
  {
    question: "who is the superior of the largest community",
    expected: {
      intent: "composed_community_query",
      role: "largest",
      topic: "superior",
    },
  },
  {
    question: "who is superior of the biggest community",
    expected: {
      intent: "composed_community_query",
      role: "largest",
      topic: "superior",
    },
  },
  {
    question: "who is the superior of the smallest community",
    expected: {
      intent: "composed_community_query",
      role: "smallest",
      topic: "superior",
    },
  },
  {
    question: "who are the members of the largest community",
    expected: {
      intent: "composed_community_query",
      role: "largest",
      topic: "members",
      outputType: "records",
    },
  },
  {
    question: "how many members are in the largest community",
    expected: {
      intent: "composed_community_query",
      role: "largest",
      topic: "members",
      outputType: "count",
    },
  },
  {
    question: "who lived in the largest community in 2015",
    expected: {
      intent: "composed_community_query",
      role: "largest",
      topic: "members",
      year: 2015,
    },
  },
  {
    question: "which was the largest community in 2015",
    expected: { intent: "historical_community_ranking", year: 2015 },
  },
]);

cases("implicit domains remain conservative", [
  {
    question: "who is over 60",
    expected: { intent: "age_search", age: 60, ageComparison: "above" },
  },
  {
    question: "who are under 50",
    expected: { intent: "age_search", age: 50, ageComparison: "below" },
  },
  {
    question: "how many are there",
    expected: { intent: "clarification_needed", topic: "count_domain" },
  },
]);

cases("organization identity precedes generic person search", [
  {
    question: "What congregation is this?",
    expected: { intent: "organization_identity", entity: "congregation_name" },
  },
  {
    question: "What is our congregation motto?",
    expected: { intent: "organization_identity", entity: "congregation_motto" },
  },
  {
    question: "Who founded the congregation?",
    expected: { intent: "organization_identity", entity: "founder" },
  },
  {
    question: "When was the congregation founded?",
    expected: { intent: "organization_identity", entity: "founded_year" },
  },
  {
    question: "Where is the General Administration?",
    expected: {
      intent: "organization_identity",
      entity: "general_administration",
    },
  },
  {
    question: "Where is the Generalate?",
    expected: {
      intent: "organization_identity",
      entity: "general_administration",
    },
  },
  {
    question: "Who is the Superior General?",
    expected: { intent: "organization_identity", entity: "superior_general" },
  },
  {
    question: "Who is the Assistant Superior General?",
    expected: {
      intent: "organization_identity",
      entity: "assistant_superior_general",
    },
  },
  {
    question: "Who is the General Treasurer?",
    expected: { intent: "organization_identity", entity: "general_treasurer" },
  },
  {
    question: "Who are the General Councillors?",
    expected: {
      intent: "organization_identity",
      entity: "general_councillors",
    },
  },
  {
    question: "What is our Province called?",
    expected: { intent: "organization_identity", entity: "province_name" },
  },
  {
    question: "What is the Province motto?",
    expected: { intent: "organization_identity", entity: "province_motto" },
  },
]);

cases("province-wide qualifications and experience", [
  {
    question: "Who has an M.Ed.?",
    expected: { intent: "education_qualification_search", entity: "M.Ed." },
  },
  {
    question: "Who has an M.Th.?",
    expected: { intent: "education_qualification_search", entity: "M.Th." },
  },
  {
    question: "Who studied theology?",
    expected: { intent: "education_qualification_search", entity: "theology" },
  },
  {
    question: "Who has a Master's degree?",
    expected: { intent: "education_qualification_search", entity: "master" },
  },
  {
    question: "Who studied at University X?",
    expected: {
      intent: "education_qualification_search",
      entity: "University X",
    },
  },
  {
    question: "Who studied outside India?",
    expected: {
      intent: "education_qualification_search",
      entity: "outside_india",
    },
  },
  {
    question: "Who has formation experience?",
    expected: { intent: "ministry_experience_search", entity: "formation" },
  },
  {
    question: "What qualifications does Fr. Thomas have?",
    expected: { intent: "member_profile", entity: "Thomas" },
  },
  {
    question: "who has theology masters",
    expected: { intent: "education_qualification_search", entity: "theology" },
  },
  {
    question: "who has formation diploma",
    expected: {
      intent: "education_qualification_search",
      entity: "formation diploma",
    },
  },
  {
    question: "who has BTh",
    expected: { intent: "education_qualification_search", entity: "BTh" },
  },
  {
    question: "who can be formation director",
    expected: { intent: "eligibility_search", role: "formation_director" },
  },
  {
    question: "is Joseph Varghese eligible to be Provincial",
    expected: {
      intent: "eligibility_search",
      entity: "Joseph Varghese",
      role: "provincial",
    },
  },
  {
    question: "which current appointments are compliant",
    expected: { intent: "appointment_compliance", topic: "summary" },
  },
  {
    question: "show appointment compliance issues",
    expected: { intent: "appointment_compliance", topic: "issues" },
  },
]);

cases("authorized contact facts remain explicit profile intents", [
  {
    question: "show Joseph Varghese's email",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "email",
    },
  },
  {
    question: "show Joseph Varghese's phone",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "phone",
    },
  },
  {
    question: "show Joseph Varghese's address",
    expected: {
      intent: "member_profile",
      entity: "Joseph Varghese",
      topic: "address",
    },
  },
]);

cases("age threshold direction", [
  {
    question: "Who are above 70 years old?",
    expected: {
      intent: "age_search",
      age: 70,
      ageComparison: "above",
      outputType: "records",
    },
  },
  {
    question: "members over 70",
    expected: { intent: "age_search", age: 70, ageComparison: "above" },
  },
  {
    question: "religious above age 70",
    expected: { intent: "age_search", age: 70, ageComparison: "above" },
  },
  {
    question: "who are above 60 years old",
    expected: { intent: "age_search", age: 60, ageComparison: "above" },
  },
  {
    question: "who are above 70 years old",
    expected: { intent: "age_search", age: 70, ageComparison: "above" },
  },
  {
    question: "religious below 40",
    expected: { intent: "age_search", age: 40, ageComparison: "below" },
  },
  {
    question: "members age 70+",
    expected: { intent: "age_search", age: 70, ageComparison: "above" },
  },
  {
    question: "members between 40 and 60",
    expected: { intent: "age_search", age: 40, ageTo: 60 },
  },
  {
    question: "members exactly 50 years old",
    expected: { intent: "age_search", age: 50, ageTo: 50 },
  },
  {
    question: "Show members above 70.",
    expected: { intent: "age_search", age: 70, ageComparison: "above" },
  },
  {
    question: "Who is older than 75?",
    expected: { intent: "age_search", age: 75, ageComparison: "above" },
  },
  {
    question: "Members under 40.",
    expected: { intent: "age_search", age: 40, ageComparison: "below" },
  },
  {
    question: "How many members are over 65?",
    expected: { intent: "age_search", age: 65, ageComparison: "above" },
  },
]);

cases("historical provincial office routing", [
  {
    question: "Who was the provincial in 2005?",
    expected: {
      intent: "historical_office_holder",
      role: "provincial",
      year: 2005,
      outputType: "records",
    },
  },
  {
    question: "provincial 2005",
    expected: {
      intent: "historical_office_holder",
      role: "provincial",
      year: 2005,
    },
  },
  {
    question: "who served as provincial during 2005",
    expected: {
      intent: "historical_office_holder",
      role: "provincial",
      year: 2005,
    },
  },
  {
    question: "Who was Assistant Provincial in 2005?",
    expected: {
      intent: "historical_office_holder",
      role: "assistant_provincial",
      year: 2005,
    },
  },
  {
    question: "who was the Provincial in 2005?",
    expected: {
      intent: "historical_office_holder",
      role: "provincial",
      year: 2005,
    },
  },
  {
    question: "who served as provincial during 2005",
    expected: {
      intent: "historical_office_holder",
      role: "provincial",
      year: 2005,
    },
  },
  {
    question: "who led the province in 2005",
    expected: {
      intent: "historical_office_holder",
      role: "provincial",
      year: 2005,
    },
  },
  {
    question: "who was the provincial secretary in 2015",
    expected: {
      intent: "historical_office_holder",
      role: "provincial_secretary",
      year: 2015,
    },
  },
  {
    question: "who was secretary in 2015",
    expected: {
      intent: "historical_office_holder",
      role: "provincial_secretary",
      year: 2015,
    },
  },
  {
    question: "provincial secretary 2015",
    expected: {
      intent: "historical_office_holder",
      role: "provincial_secretary",
      year: 2015,
    },
  },
  {
    question: "secretary of the province in 2015",
    expected: {
      intent: "historical_office_holder",
      role: "provincial_secretary",
      year: 2015,
    },
  },
  {
    question: "who served as provincial secretary during 2015",
    expected: {
      intent: "historical_office_holder",
      role: "provincial_secretary",
      year: 2015,
    },
  },
]);

cases("historical governance body routing outranks generic provincial", [
  {
    question: "who were the provincial council members in 2020",
    expected: {
      intent: "governance_body_membership",
      topic: "provincial_council",
      year: 2020,
      outputType: "records",
    },
  },
  {
    question: "provincial council 2020",
    expected: {
      intent: "governance_body_membership",
      topic: "provincial_council",
      year: 2020,
    },
  },
  {
    question: "who was on the provincial council in 2020",
    expected: {
      intent: "governance_body_membership",
      topic: "provincial_council",
      year: 2020,
    },
  },
  {
    question: "council members in 2020",
    expected: {
      intent: "governance_body_membership",
      topic: "provincial_council",
      year: 2020,
    },
  },
  {
    question: "members of provincial council in 2020",
    expected: {
      intent: "governance_body_membership",
      topic: "provincial_council",
      year: 2020,
    },
  },
  {
    question: "who served on council in 2020",
    expected: {
      intent: "governance_body_membership",
      topic: "provincial_council",
      year: 2020,
    },
  },
]);

cases("current governance bodies use dedicated intents", [
  {
    question: "list governance bodies",
    expected: { intent: "governance_directory" },
  },
  {
    question: "show governance bodies",
    expected: { intent: "governance_directory" },
  },
  {
    question: "tell me about the Education Commission",
    expected: {
      intent: "governance_body_profile",
      entity: "education commission",
    },
  },
  {
    question: "tell me about the Finance Committee",
    expected: {
      intent: "governance_body_profile",
      entity: "finance committee",
    },
  },
  {
    question: "who belongs to education commission",
    expected: {
      intent: "governance_body_members",
      entity: "education commission",
    },
  },
  {
    question: "who belongs to finance commission",
    expected: {
      intent: "governance_body_members",
      entity: "finance commission",
    },
  },
  {
    question: "members of sustainability commission",
    expected: {
      intent: "governance_body_members",
      entity: "sustainability commission",
    },
  },
  {
    question: "who chairs the Education Commission",
    expected: {
      intent: "governance_body_leader",
      entity: "education commission",
    },
  },
  {
    question: "who chaired the education commission",
    expected: {
      intent: "governance_body_leader",
      entity: "education commission",
    },
  },
  {
    question: "who is president of the Provincial Council",
    expected: {
      intent: "governance_body_leader",
      entity: "provincial council",
    },
  },
]);

Deno.test("governance follow-up uses a singular body focus", () => {
  const actual = interpretAskCommunioQuestion("Who chairs it?", {
    focus_entity_type: "governance_body",
    focus_entity_id: "body-1",
    focus_entity_name: "Education Commission",
  });
  assertEquals(
    actual.intent,
    "governance_body_leader",
    "governance follow-up intent",
  );
  assertEquals(
    actual.entity,
    "Education Commission",
    "governance follow-up entity",
  );
  assertEquals(actual.entityId, "body-1", "governance follow-up ID");
});

cases("appointment expiry supported semantics", [
  {
    question: "Which appointments are ending soon?",
    expected: { intent: "appointment_expiry" },
  },
  {
    question: "Show appointments ending in the next 90 days.",
    expected: { intent: "appointment_expiry" },
  },
  {
    question: "Which offices expire this year?",
    expected: {
      intent: "appointment_expiry",
      year: new Date().getUTCFullYear(),
    },
  },
]);

const ambiguityCases: Case[] = [
  {
    question: "Tell me about Joseph.",
    expected: { intent: "person_search", entity: "Joseph" },
  },
  {
    question: "Where is Antony?",
    expected: { intent: "person_search", entity: "Antony" },
  },
  {
    question: "Show Thomas.",
    expected: { intent: "person_search", entity: "Thomas" },
  },
];
cases("ambiguous names preserve raw entity text", ambiguityCases);

cases(
  "unsupported questions use the existing fallback",
  [
    "What is the weather today?",
    "Write a homily for Sunday.",
    "Who will win the election?",
    "What should we build next year?",
  ].map((question) => ({ question, expected: { intent: "unknown" } })),
);

cases("demo terminology routes only current organization vocabulary", [
  {
    question: "What is Missionaries of St. Antony?",
    expected: { intent: "organization_identity", entity: "congregation_name" },
  },
  {
    question: "What is the Indian Province called?",
    expected: { intent: "organization_identity", entity: "province_name" },
  },
  {
    question: "Show communities in St. Antony.",
    expected: { intent: "location_entity_search", entity: "St. Antony" },
  },
  {
    question: "Tell me about Marianists.",
    expected: { intent: "person_search", entity: "Marianists" },
  },
  {
    question: "Who is Chaminade?",
    expected: { intent: "person_search", entity: "Chaminade" },
  },
]);

const reachabilityCases: Case[] = [
  {
    question: "list governance bodies",
    expected: { intent: "governance_directory" },
  },
  {
    question: "tell me about Education Commission",
    expected: { intent: "governance_body_profile" },
  },
  {
    question: "members of Finance Commission",
    expected: { intent: "governance_body_members" },
  },
  {
    question: "who chairs Sustainability Commission",
    expected: { intent: "governance_body_leader" },
  },
  ...decisionCases,
  ...ambiguityCases,
  {
    question: "Show current assignment for St. Antony Community.",
    expected: { intent: "current_assignment" },
  },
  {
    question: "Who lived in St. Antony Community?",
    expected: { intent: "community_membership_history" },
  },
  {
    question: "Show Superior history of St. Antony Community.",
    expected: { intent: "community_superior_history" },
  },
  {
    question: "Who served at St. Antony School?",
    expected: { intent: "ministry_assignment_history" },
  },
  {
    question: "Who were the Principals of St. Antony School?",
    expected: { intent: "ministry_leadership_history" },
  },
  {
    question: "Who is the Provincial Secretary?",
    expected: { intent: "appointment_search" },
  },
  {
    question: "Who was Provincial in 2005?",
    expected: { intent: "historical_office_holder" },
  },
  {
    question: "Who was on the Provincial Council in 2020?",
    expected: { intent: "governance_body_membership" },
  },
  {
    question: "show the appointment history of Joseph Varghese",
    expected: { intent: "member_appointment_history" },
  },
  {
    question: "where is Joseph Varghese now",
    expected: { intent: "member_current_location" },
  },
  {
    question: "where was Joseph Varghese in 2010",
    expected: { intent: "member_historical_location" },
  },
  {
    question: "largest community",
    expected: { intent: "community_size_ranking" },
  },
  {
    question: "who is the oldest member",
    expected: { intent: "member_age_extreme" },
  },
  {
    question: "average age of members",
    expected: { intent: "member_analytics" },
  },
  {
    question: "how many communities have fewer than 5 members",
    expected: { intent: "community_size_threshold" },
  },
  {
    question: "which ministry has the most members",
    expected: { intent: "ministry_size_ranking" },
  },
  {
    question: "how many are there",
    expected: { intent: "clarification_needed" },
  },
  {
    question: "who is the superior of the largest community",
    expected: { intent: "composed_community_query" },
  },
  {
    question: "list all communities",
    expected: { intent: "community_directory" },
  },
  {
    question: "show St Antony Community",
    expected: { intent: "community_profile" },
  },
  { question: "list schools", expected: { intent: "ministry_directory" } },
  {
    question: "where is St Antony School",
    expected: { intent: "ministry_profile" },
  },
  {
    question: "list past provincials",
    expected: { intent: "leadership_history" },
  },
  {
    question: "Who is the principal of Budakata School?",
    expected: { intent: "member_safe_factual" },
  },
  {
    question: "Who made first profession in 1990?",
    expected: { intent: "profession_cohort" },
  },
  {
    question: "Who was ordained in 2000?",
    expected: { intent: "ordination_cohort" },
  },
  {
    question: "Who has an M.Ed.?",
    expected: { intent: "education_qualification_search" },
  },
  {
    question: "Which current appointments are compliant?",
    expected: { intent: "appointment_compliance" },
  },
  {
    question: "Who has formation experience?",
    expected: { intent: "ministry_experience_search" },
  },
  {
    question: "Who is from Kerala?",
    expected: { intent: "member_origin_search" },
  },
  {
    question: "Who is serving in Kerala?",
    expected: { intent: "current_location_search" },
  },
  { question: "Members above 70.", expected: { intent: "age_search" } },
  {
    question: "Which appointments are ending soon?",
    expected: { intent: "appointment_expiry" },
  },
  {
    question: "What congregation is this?",
    expected: { intent: "organization_identity" },
  },
  {
    question: "Where has Fr. Thomas served?",
    expected: { intent: "member_history" },
  },
  {
    question: "What is Fr. Thomas's Religious ID?",
    expected: { intent: "member_profile" },
  },
  {
    question: "what languages does Joseph Varghese speak",
    expected: { intent: "member_languages" },
  },
  { question: "Who joined in 1985?", expected: { intent: "vocation_cohort" } },
  {
    question: "How many active members do we have?",
    expected: { intent: "present_state" },
  },
  {
    question: "Which communities are in Kerala?",
    expected: { intent: "location_entity_search" },
  },
  { question: "What is the weather?", expected: { intent: "unknown" } },
  {
    question: "history of St Antony Community",
    expected: { intent: "community_history" },
  },
  {
    question: "communities opened in 2015",
    expected: { intent: "community_lifecycle" },
  },
  {
    question: "who transferred from St Antony Community in 2015",
    expected: { intent: "formal_transfer" },
  },
  {
    question: "who joined St Antony Community in 2015",
    expected: { intent: "community_movement" },
  },
  {
    question: "which was the largest community in 2015",
    expected: { intent: "historical_community_ranking" },
  },
  {
    question: "members working in schools",
    expected: { intent: "ministry_type_staffing" },
  },
  {
    question: "who succeeded Thomas Mathew",
    expected: { intent: "leadership_successor" },
  },
  {
    question: "how long did Joseph serve as Provincial",
    expected: { intent: "member_office_tenure" },
  },
  {
    question: "previous assignment of Joseph Varghese",
    expected: { intent: "previous_assignment" },
  },
  {
    question: "appointments before 2010",
    expected: { intent: "appointment_period_search" },
  },
  {
    question: "compare appointments of Joseph and Thomas",
    expected: { intent: "member_appointment_comparison" },
  },
  {
    question: "September birthdays",
    expected: { intent: "birthday_month" },
  },
  {
    question: "10th first profession anniversary next year",
    expected: { intent: "vocation_anniversary" },
  },
  {
    question: "when was St. Antony College started",
    expected: { intent: "ministry_establishment" },
  },
];

Deno.test("every interpreter result is handled and every handler is reachable", () => {
  const reached = new Set<AskCommunioIntent>();
  for (const testCase of reachabilityCases) {
    const result = interpretAskCommunioQuestion(testCase.question);
    assertEquals(
      handledAskCommunioIntents.has(result.intent),
      true,
      `${result.intent} has a handler`,
    );
    reached.add(result.intent);
  }
  for (const intent of handledAskCommunioIntents) {
    assertEquals(reached.has(intent), true, `${intent} is reachable`);
  }
});

Deno.test("decision boundary cannot fall through to a database intent", () => {
  for (const { question } of decisionCases.slice(0, 8)) {
    const result = interpretAskCommunioQuestion(question);
    assertEquals(result.intent, "decision_boundary", question);
  }
});

Deno.test("singular member context resolves deterministic follow-ups", () => {
  const context = {
    last_intent: "member_age_extreme",
    primary_entity_type: "member",
    primary_entity_id: "member-joseph",
    primary_entity_name: "Joseph Varghese",
    last_result_count: 1,
  };
  const followUps: Case[] = [
    {
      question: "where is he now",
      expected: {
        intent: "member_current_location",
        entity: "Joseph Varghese",
        entityId: "member-joseph",
      },
    },
    {
      question: "what appointments has he held",
      expected: {
        intent: "member_appointment_history",
        entity: "Joseph Varghese",
      },
    },
    {
      question: "where was he in 2010",
      expected: {
        intent: "member_historical_location",
        entity: "Joseph Varghese",
        year: 2010,
      },
    },
    {
      question: "which community was he in during 2010",
      expected: { intent: "member_historical_location", year: 2010 },
    },
    {
      question: "when did he make final profession",
      expected: { intent: "member_history", topic: "final_profession" },
    },
    {
      question: "when was he ordained",
      expected: { intent: "member_history", topic: "ordination" },
    },
  ];
  for (const { question, expected } of followUps) {
    const actual = interpretAskCommunioQuestion(question, context);
    for (const [key, value] of Object.entries(expected)) {
      assertEquals(
        actual[key as keyof AskCommunioInterpretation],
        value,
        `${question} (${key})`,
      );
    }
  }
});

Deno.test("singular community context resolves deterministic follow-ups", () => {
  const context = {
    last_intent: "community_size_ranking",
    primary_entity_type: "community",
    primary_entity_id: "community-antony",
    primary_entity_name: "St. Antony Scholasticate, Pune",
    last_result_count: 1,
  };
  const followUps: Case[] = [
    {
      question: "who are its members",
      expected: {
        intent: "community_membership_history",
        topic: "current",
        entityId: "community-antony",
      },
    },
    {
      question: "who is the superior there",
      expected: { intent: "community_superior_history", topic: "current" },
    },
    {
      question: "who lived there in 2015",
      expected: { intent: "community_membership_history", year: 2015 },
    },
    {
      question: "how many members are there",
      expected: {
        intent: "community_membership_history",
        topic: "current",
        outputType: "count",
      },
    },
  ];
  for (const { question, expected } of followUps) {
    const actual = interpretAskCommunioQuestion(question, context);
    for (const [key, value] of Object.entries(expected)) {
      assertEquals(
        actual[key as keyof AskCommunioInterpretation],
        value,
        `${question} (${key})`,
      );
    }
  }
});

Deno.test("ambiguous context never selects an arbitrary entity", () => {
  const member = interpretAskCommunioQuestion("where is he", {
    last_intent: "age_search",
    ambiguous_entity_type: "member",
    last_result_count: 6,
  });
  assertEquals(member.intent, "clarification_needed", "plural member context");
  assertEquals(member.topic, "member_reference", "plural member clarification");
  const community = interpretAskCommunioQuestion("who is the superior there", {
    last_intent: "community_size_ranking",
    ambiguous_entity_type: "community",
    last_result_count: 3,
  });
  assertEquals(
    community.intent,
    "clarification_needed",
    "tied community context",
  );
  assertEquals(
    community.topic,
    "community_reference",
    "tied community clarification",
  );
});

Deno.test("an explicit entity overrides prior context", () => {
  const actual = interpretAskCommunioQuestion("where is Francis Thomas now", {
    primary_entity_type: "member",
    primary_entity_id: "member-joseph",
    primary_entity_name: "Joseph Varghese",
  });
  assertEquals(
    actual.intent,
    "member_current_location",
    "explicit member intent",
  );
  assertEquals(actual.entity, "Francis Thomas", "explicit member entity");
});

Deno.test("community focus survives a singular superior answer", () => {
  const afterSuperior = {
    focus_entity_type: "community",
    focus_entity_id: "community-antony",
    focus_entity_name: "St. Antony Scholasticate, Pune",
    last_answer_entity_type: "member",
    last_answer_entity_id: "member-superior",
    last_answer_entity_name: "Fr. Superior",
    entity_set_type: "member",
    entity_set_size: 1,
  };
  const members = interpretAskCommunioQuestion(
    "who are its members",
    afterSuperior,
  );
  assertEquals(
    members.intent,
    "community_membership_history",
    "community focus members",
  );
  assertEquals(members.entityId, "community-antony", "community focus id");
  const historical = interpretAskCommunioQuestion(
    "who lived there in 2015",
    afterSuperior,
  );
  assertEquals(
    historical.intent,
    "community_membership_history",
    "community focus history",
  );
  assertEquals(historical.year, 2015, "community focus year");
  const person = interpretAskCommunioQuestion("where is he now", afterSuperior);
  assertEquals(person.intent, "member_current_location", "last answer person");
  assertEquals(person.entityId, "member-superior", "last answer member id");
});

Deno.test("semantic entity sets distinguish ties from supporting evidence", () => {
  const tied = interpretAskCommunioQuestion("who is the superior there", {
    entity_set_type: "community",
    entity_set_size: 5,
    ambiguous_entity_type: "community",
  });
  assertEquals(tied.intent, "clarification_needed", "genuine community tie");
  const winner = interpretAskCommunioQuestion("who is the superior there", {
    focus_entity_type: "community",
    focus_entity_id: "winner",
    focus_entity_name: "Winning Community",
    entity_set_size: 19,
  });
  assertEquals(
    winner.intent,
    "community_superior_history",
    "evidence count is not ambiguity",
  );
  assertEquals(winner.entityId, "winner", "winning community id");
});
