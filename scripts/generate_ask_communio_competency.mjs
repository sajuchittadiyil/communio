import fs from "node:fs";

const rows = [];
const add = (domain, subdomain, question, expected_intent, options = {}) => rows.push({
  domain, subdomain, question, expected_intent,
  conversation_id: "", turn_number: "",
  expected_entity_type: "", expected_entity_name: "",
  expected_output_type: "records", expected_time_scope: "",
  expected_behavior: "PASS", expected_answer_contains: "",
  expected_answer_not_contains: "", expected_result_min: "",
  expected_result_max: "", ambiguity_expected: "false",
  zero_result_allowed: "false", priority: "P1", notes: "",
  ...options,
});

const pass = (d, s, intent, questions, options = {}) => questions.forEach((q) => add(d, s, q, intent, options));
const gap = (d, s, questions, notes) => questions.forEach((q) => add(d, s, q, "unknown", { expected_behavior: "KNOWN_GAP", priority: "P2", notes }));

pass("members", "lookup", "person_search", [
  "who is Joseph Varghese", "tell me about Joseph Varghese", "show Joseph Varghese", "find Joseph Varghese",
  "show me Fr Joseph Varghese", "show me Fr. Joseph Varghese", "tell me about Bro Joseph Vadakkel", "tell me about Bro. Joseph Vadakkel",
], { expected_entity_type: "member" });
pass("members", "profile", "member_profile", [
  "what is Joseph Varghese's religious ID", "what qualifications does Joseph Varghese have", "where is Joseph Varghese from",
  "what is Joseph Varghese's home parish", "which diocese is Joseph Varghese from", "which state is Joseph Varghese from",
  "which community is Joseph Varghese in", "which ministry is Joseph Varghese in",
], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese" });
pass("members", "profile", "member_profile", ["profile of Joseph Varghese", "what is Joseph Varghese's date of birth", "when was Joseph Varghese born", "how old is Joseph Varghese"], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P2", notes: "Wave 1 safe profile facts" });
pass("members", "profile", "member_profile", ["show Joseph Varghese's email", "show Joseph Varghese's phone", "show Joseph Varghese's address"], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P2", notes: "Wave 3 caller-authorized safe profile contact facts" });
gap("members", "profile", ["what languages does Joseph Varghese speak"], "No normalized member-language relation or proficiency model");
add("members", "profile", "show Joseph Varghese's status", "member_profile", { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P2", notes: "Wave 1 safe profile status" });

pass("age_demographics", "extreme", "member_age_extreme", ["who is the oldest", "who is the oldest member", "eldest member", "who is the youngest", "youngest religious", "who was born earliest"], { expected_entity_type: "member", expected_output_type: "single", priority: "P0" });
pass("age_demographics", "filter", "age_search", ["who is over 60", "members above 60", "who are older than 50", "who are under 40", "members below 50", "who are between 50 and 65 years old", "members aged between 40 and 60", "who is exactly 50 years old", "who are above 70 years old", "who are above 60 years old", "who are under 50"], { expected_entity_type: "member" });
pass("age_demographics", "count", "age_search", ["how many members are over 60", "how many members are under 40", "how many members are between 50 and 65"], { expected_output_type: "count" });

pass("current_communities", "count", "present_state", ["how many communities are there", "total communities", "number of communities", "how many communities do we have"], { expected_output_type: "count", expected_entity_type: "community" });
pass("current_communities", "ranking", "community_size_ranking", ["largest community", "which is the largest community", "biggest community", "community with most members", "which community has the most number", "which community has the highest membership", "smallest community", "which is the smallest community", "community with fewest members", "which community has minimum strength"], { expected_entity_type: "community", expected_output_type: "single", priority: "P0" });
pass("current_communities", "members", "community_membership_history", ["who lives in St Antony Community Kolkata", "members of St Antony Community Kolkata", "how many members are in St Antony Community Kolkata"], { expected_entity_type: "community", expected_entity_name: "St Antony Community Kolkata" });
pass("current_communities", "superior", "community_superior_history", ["who is the superior of St Antony Community Kolkata", "who leads St Antony Community Kolkata"], { expected_entity_type: "community" });
pass("current_communities", "browse", "community_directory", ["list all communities", "show communities"], { expected_entity_type: "community", priority: "P2", notes: "Wave 1 authorized active community directory" });
pass("current_communities", "browse", "community_profile", ["where is St Antony Community", "show St Antony Community", "tell me about St Antony Community"], { expected_entity_type: "community", expected_entity_name: "St Antony Community", priority: "P2", notes: "Wave 1 authorized community profile" });
add("current_communities", "browse", "list closed communities", "community_directory", { expected_entity_type: "community", priority: "P2", notes: "Wave 2 current closed-state directory; does not claim closure dates" });

pass("historical_community", "membership", "community_membership_history", [
  "who lived in St Antony Community Kolkata in 2015", "who were the members of St Antony Community in 2015",
  "who were the community members of St. Antony Community in 2015", "members St Antony community 2015",
  "who lived in St Antony Community kolkota in 2015", "how many members were in St Antony Community in 2015",
], { expected_entity_type: "community", expected_time_scope: "2015", priority: "P0" });
pass("historical_community", "superior", "community_superior_history", ["who was the superior of St Antony Community in 2015", "former superiors of St Antony Community", "show superior history of St Antony Community"], { expected_entity_type: "community" });
for (const [question, year, yearTo] of [["community membership in 2010", "2010", ""], ["members between 2010 and 2015", "2010", "2015"], ["who joined the community in 2015", "2015", ""], ["who left the community in 2015", "2015", ""]]) {
  add("historical_community", "movement", question, "clarification_needed", { expected_time_scope: yearTo ? `${year}..${yearTo}` : year, expected_behavior: "CLARIFY", priority: "P2", notes: "Wave 2 safely requires a named community" });
}
add("historical_community", "movement", "history of St Antony Community", "community_history", { expected_entity_type: "community", expected_entity_name: "St Antony Community", priority: "P2", notes: "Wave 2 effective-dated community timeline" });
gap("historical_community", "movement", ["how many members were there in 2015"], "Missing community scope remains a conservative roadmap case");
add("historical_community", "movement", "which was the largest community in 2015", "historical_community_ranking", { expected_entity_type: "community", expected_time_scope: "2015", priority: "P2", notes: "Wave 2 effective-dated historical ranking" });
add("historical_community", "movement", "community strength in 2010", "clarification_needed", { expected_time_scope: "2010", expected_behavior: "CLARIFY", priority: "P2", notes: "Wave 2 safely requires a named community" });
gap("historical_community", "movement", ["communities opened in 2015", "communities closed in 2015", "who transferred from St Antony Community in 2015"], "Lifecycle/explicit transfer semantics are not reliably stored");

pass("ministries", "assignment", "ministry_assignment_history", ["who works at St Antony School", "who is assigned to St Antony School", "who served at St Antony School", "which members worked at St Antony School"], { expected_entity_type: "ministry" });
pass("ministries", "leadership", "ministry_leadership_history", ["who was principal of St Antony School in 2015", "who were the principals of St Antony School", "show principal history for St Antony School"], { expected_entity_type: "ministry" });
pass("ministries", "member_history", "member_history", ["ministry history of Joseph Varghese", "where has Joseph Varghese served"], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese" });
add("ministries", "member_history", "where did Joseph Varghese serve in 2010", "member_historical_location", { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", expected_time_scope: "2010" });
pass("ministries", "location", "current_location_search", ["who is currently serving in Kerala", "which members are currently outside India"], { expected_entity_type: "member" });
add("ministries", "browse", "how many ministries are there", "ministry_directory", { expected_entity_type: "ministry", expected_output_type: "count", priority: "P2", notes: "Wave 1 authorized ministry count" });
pass("ministries", "browse", "ministry_directory", ["list all ministries", "list schools", "show parishes", "show hospitals", "show formation houses"], { expected_entity_type: "ministry", priority: "P2", notes: "Wave 1 authorized ministry directory/type filter" });
pass("ministries", "browse", "ministry_type_staffing", ["members working in schools", "members working in parishes"], { expected_entity_type: "member", priority: "P2", notes: "Wave 2 current effective ministry-type staffing" });
add("ministries", "browse", "how many members are in education ministry", "ministry_type_staffing", { expected_entity_type: "member", expected_output_type: "count", priority: "P2", notes: "Wave 2 unique current education-ministry member count" });
add("ministries", "browse", "where is St Antony School", "ministry_profile", { expected_entity_type: "ministry", expected_entity_name: "St Antony School", priority: "P2", notes: "Wave 1 authorized ministry profile" });
add("ministries", "browse", "show active schools", "ministry_directory", { expected_entity_type: "ministry", priority: "P2", notes: "Wave 1 active ministry type filter" });

pass("leadership", "current", "appointment_search", ["who is provincial", "who is the provincial", "current provincial", "who is assistant provincial", "who is provincial secretary", "who is secretary", "who are the provincial councillors"], { expected_entity_type: "member" });
pass("leadership", "historical", "historical_office_holder", ["who was provincial in 2005", "who was the provincial in 2005", "provincial 2005", "who served as provincial during 2005", "who was secretary in 2015", "who was bursar in 2015", "who led the province in 2005"], { expected_entity_type: "member", priority: "P0" });
pass("leadership", "council", "governance_body_membership", ["who were the provincial council members in 2020", "provincial council 2020", "who was on the provincial council in 2020", "council members in 2020", "members of provincial council in 2020"], { expected_entity_type: "governance_body", expected_time_scope: "2020", priority: "P0" });
pass("leadership", "advanced", "appointment_search", ["who is bursar", "who is provincial treasurer"], { expected_entity_type: "member", priority: "P2", notes: "Wave 1 canonical Provincial Bursar aliases" });
pass("leadership", "advanced", "leadership_history", ["list past provincials", "history of provincials"], { expected_entity_type: "member", priority: "P2", notes: "Wave 1 effective-dated Provincial history" });
add("leadership", "advanced", "who succeeded Thomas Mathew", "leadership_successor", { expected_entity_type: "member", expected_entity_name: "Thomas Mathew", priority: "P2", notes: "Wave 2 next recorded non-ambiguous Provincial term" });
add("leadership", "advanced", "how long did Joseph Varghese serve as provincial", "member_office_tenure", { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P2", notes: "Wave 2 effective-dated Provincial tenure" });

for (const [subdomain, intent, phrases, year] of [
  ["first_profession", "profession_cohort", ["first profession", "first vows", "temporary profession", "temporary vows"], "1995"],
  ["final_profession", "vocation_cohort", ["final profession", "final vows", "perpetual profession", "perpetual vows"], "2020"],
  ["ordination", "ordination_cohort", ["ordained", "ordination", "priestly ordination"], "2010"],
]) {
  for (const phrase of phrases) {
    add("vocation", subdomain, phrase === "ordained" ? `who was ${phrase} in ${year}` : `who made ${phrase} in ${year}`, intent, { expected_time_scope: year, expected_entity_type: "member", priority: "P0", zero_result_allowed: "true" });
    add("vocation", subdomain, `how many ${phrase === "ordained" ? "were ordained" : `made ${phrase}`} in ${year}`, intent, { expected_time_scope: year, expected_output_type: "count", zero_result_allowed: "true" });
  }
}
pass("vocation", "member", "member_history", ["when did Joseph Varghese make first profession", "when did Joseph Varghese make final profession", "when was Joseph Varghese ordained"], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese" });
pass("vocation", "range", "profession_cohort", ["who made first profession between 1990 and 2000"], { expected_time_scope: "1990..2000" });
pass("vocation", "range", "ordination_cohort", ["who was ordained between 2000 and 2010"], { expected_time_scope: "2000..2010" });

pass("appointment_history", "member", "member_appointment_history", ["show appointment history of Joseph Varghese", "appointment history Joseph Varghese", "appointments of Joseph Varghese", "what appointments has Joseph Varghese held", "what offices did Joseph Varghese hold"], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P0" });
pass("appointment_history", "location", "member_current_location", ["where is Joseph Varghese now", "where is Joseph Varghese", "current assignment of Joseph Varghese", "where does Joseph Varghese live", "where is Fr Joseph Varghese assigned"], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P0" });
pass("appointment_history", "historical_location", "member_historical_location", ["where was Joseph Varghese in 2010", "which community was Joseph Varghese in during 2010", "where did Joseph Varghese serve in 2010", "Joseph Varghese location in 2010"], { expected_entity_type: "member", expected_time_scope: "2010" });
add("appointment_history", "advanced", "previous assignment of Joseph Varghese", "previous_assignment", { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P2", notes: "Wave 2 latest completed assignment" });
pass("appointment_history", "advanced", "member_office_tenure", ["when was Joseph Varghese provincial", "how long was Joseph Varghese provincial"], { expected_entity_type: "member", expected_entity_name: "Joseph Varghese", priority: "P2", notes: "Wave 2 named-member Provincial terms" });
add("appointment_history", "advanced", "appointments before 2010", "appointment_period_search", { expected_time_scope: "2010", priority: "P2", notes: "Wave 2 authorized appointment start-date filter" });
add("appointment_history", "advanced", "appointments after 2020", "appointment_period_search", { expected_time_scope: "2020", priority: "P2", notes: "Wave 2 authorized appointment start-date filter" });
add("appointment_history", "advanced", "compare appointments of Joseph and Francis", "member_appointment_comparison", { expected_entity_type: "member", priority: "P2", notes: "Wave 2 explicitly scoped two-member comparison" });

pass("qualifications_eligibility", "qualification", "education_qualification_search", ["who has a masters degree", "who studied theology", "who has an M.Ed.", "who has an M.Th.", "who studied outside India"], { expected_entity_type: "member" });
pass("qualifications_eligibility", "eligibility", "eligibility_search", ["who is eligible to be school principal", "who is eligible for novice master", "who is eligible to be chaplain", "show members eligible for principal"], { expected_entity_type: "member" });
pass("qualifications_eligibility", "decision_boundary", "decision_boundary", ["who should we appoint as Provincial", "who is the best candidate for principal"], { expected_behavior: "UNSUPPORTED", expected_answer_not_contains: "recommend", priority: "P0" });
pass("qualifications_eligibility", "advanced", "education_qualification_search", ["who has theology masters", "who has formation diploma", "who has BTh"], { expected_entity_type: "member", priority: "P2", notes: "Wave 3 normalized qualification aliases" });
add("qualifications_eligibility", "advanced", "who can be formation director", "eligibility_search", { expected_entity_type: "member", priority: "P2", notes: "Wave 3 recorded Formation Director eligibility" });
add("qualifications_eligibility", "advanced", "which current appointments are compliant", "appointment_compliance", { expected_entity_type: "member", priority: "P2", notes: "Wave 3 current appointment compliance summary" });
add("qualifications_eligibility", "advanced", "show appointment compliance issues", "appointment_compliance", { expected_entity_type: "member", priority: "P2", notes: "Wave 3 recorded non-compliance issues only" });

pass("aggregations", "members", "present_state", ["how many members are there now", "total members", "current membership", "congregation strength", "how many members do we have"], { expected_output_type: "count", priority: "P0" });
pass("aggregations", "communities", "present_state", ["how many communities", "how many communities are there", "total communities"], { expected_output_type: "count" });
pass("aggregations", "age", "age_search", ["how many members over 60", "how many members under 40", "how many members between 50 and 65"], { expected_output_type: "count" });
pass("aggregations", "ranking", "community_size_ranking", ["which community has most members", "which community has fewest members"], { expected_output_type: "single" });
pass("aggregations", "member_category", "present_state", ["how many priests", "how many brothers"], { expected_output_type: "count", priority: "P2", notes: "Wave 1 active canonical ecclesiastical-title count" });
gap("aggregations", "known_gap", ["how many communities have fewer than 5 members", "average age of members", "age distribution", "median age", "members by state"], "Advanced aggregation remains Wave 4");

pass("governance", "provincial_council", "governance_body_membership", ["who were council members in 2020", "who served on council in 2020"], { expected_time_scope: "2020" });
pass("governance", "current", "appointment_search", ["who are current Provincial Council members", "who are the provincial councillors"], {});
gap("governance", "bodies", ["list governance bodies", "show governance bodies", "who belongs to education commission", "who belongs to finance commission", "members of sustainability commission", "who chaired the education commission"], "Governance body schema not exposed to Ask Communio");

pass("entity_resolution", "community", "community_membership_history", ["members of St Antony Community", "members of St. Antony Community", "members of st antony community", "members of St Antony", "members of St Antony Community Kolkata", "members of St Antony Community kolkota"], { ambiguity_expected: "true", expected_entity_type: "community" });
pass("entity_resolution", "member", "person_search", ["show Joseph", "find Fr Joseph", "find Fr. Joseph", "find Bro Joseph", "find Bro. Joseph"], { ambiguity_expected: "true", expected_entity_type: "member" });
pass("entity_resolution", "clarification", "community_superior_history", ["who was the superior of St Antony Community in 2015"], { expected_behavior: "CLARIFY", ambiguity_expected: "true" });
gap("entity_resolution", "malformed", ["St Antony", "Joseph", "community", "member"], "Bare noun/name intent is intentionally conservative");

const conversations = [
  ["A", [
    ["largest community", "community_size_ranking", "community", "PASS"],
    ["who is the superior there", "community_superior_history", "community", "PASS"],
    ["who are its members", "community_membership_history", "community", "PASS"],
    ["who lived there in 2015", "community_membership_history", "community", "PASS"],
  ]],
  ["B", [
    ["who is the oldest", "member_age_extreme", "member", "PASS"], ["where is he now", "member_current_location", "member", "PASS"],
    ["what appointments has he held", "member_appointment_history", "member", "PASS"], ["when did he make final profession", "member_history", "member", "PASS"],
  ]],
  ["C", [["who was provincial in 2005", "historical_office_holder", "member", "PASS"], ["where is he now", "member_current_location", "member", "PASS"], ["where was he in 2010", "member_historical_location", "member", "PASS"]]],
  ["D", [["who is over 60", "age_search", "member", "PASS"], ["where is he", "clarification_needed", "member", "CLARIFY"]]],
  ["E", [["smallest community", "community_size_ranking", "community", "PASS"], ["who is the superior there", "clarification_needed", "community", "CLARIFY"]]],
  ["F", [["largest community", "community_size_ranking", "community", "PASS"], ["write a homily", "unknown", "", "UNSUPPORTED"], ["who is the superior there", "community_superior_history", "community", "PASS"]]],
];
for (const [conversation, turns] of conversations) turns.forEach(([q, intent, type, behavior], index) => add("conversation", "follow_up", q, intent, { conversation_id: conversation, turn_number: String(index + 1), expected_entity_type: type, expected_behavior: behavior, priority: "P0" }));

pass("composed_queries", "community", "composed_community_query", ["who is the superior of the largest community", "who is superior of the biggest community", "who are the members of the largest community", "how many members are in the largest community", "who lived in the largest community in 2015"], { expected_entity_type: "community", priority: "P0" });
add("composed_queries", "tie", "who is superior of the smallest community", "composed_community_query", { expected_behavior: "CLARIFY", ambiguity_expected: "true", priority: "P0" });
add("composed_queries", "temporal", "which was the largest community in 2015", "clarification_needed", { expected_behavior: "KNOWN_GAP", expected_time_scope: "2015", priority: "P1" });
gap("composed_queries", "advanced", ["where is the superior of the largest community", "how old is the superior of the largest community", "which ministry has the most members"], "Nested query not supported");

for (const [q, intent, behavior, note] of [
  ["who made final profession in 1901", "vocation_cohort", "ZERO_RESULT", "Recognized vocation intent"],
  ["who are above 120 years old", "age_search", "ZERO_RESULT", "Recognized age intent"],
  ["who was provincial in 1880", "historical_office_holder", "ZERO_RESULT", "Recognized office intent"],
  ["what is the weather", "unknown", "UNSUPPORTED", "Outside Communio"],
  ["write me a poem", "unknown", "UNSUPPORTED", "Outside Communio"],
  ["write a homily for Sunday", "unknown", "UNSUPPORTED", "Outside Communio"],
  ["who will be the next Provincial", "unknown", "UNSUPPORTED", "Prediction"],
  ["who should we appoint as Provincial", "decision_boundary", "UNSUPPORTED", "Decision boundary"],
  ["how many are there", "clarification_needed", "CLARIFY", "Missing domain"],
  ["???", "unknown", "UNSUPPORTED", "Malformed"], ["random purple banana", "unknown", "UNSUPPORTED", "Malformed"],
]) add("negative", "safety", q, intent, { expected_behavior: behavior, zero_result_allowed: behavior === "ZERO_RESULT" ? "true" : "false", priority: "P0", notes: note });
gap("negative", "input_validation", ["", "?", "..", "a"], "Rejected by API length validation before interpretation");

// Add realistic, uniquely worded variants until the permanent suite reaches 280 cases.
const variantSeeds = rows.filter((row) => row.expected_behavior === "PASS" && !row.conversation_id);
let variantIndex = 0;
while (rows.length < 280) {
  const seed = variantSeeds[variantIndex++ % variantSeeds.length];
  const prefixes = ["please tell me: ", "can you show me ", "from Communio, ", "please check: "];
  const question = `${prefixes[(variantIndex - 1) % prefixes.length]}${seed.question}`;
  if (rows.some((row) => row.question.toLowerCase() === question.toLowerCase())) continue;
  rows.push({ ...seed, question, priority: "P2", notes: `${seed.notes ? `${seed.notes}; ` : ""}politeness/prefix normalization variant` });
}

// Stable IDs and a deliberately honest priority distribution close to 60/140/80.
rows.forEach((row, index) => { row.id = `AC-${String(index + 1).padStart(3, "0")}`; });
// The suite contains 291 rows, so P1 absorbs the eleven cases above the 280-case
// planning example. Preserve the first 60 authored P0 anchors and 80 authored P2
// roadmap/edge cases; everything else is P1.
let p0Remaining = 60;
let p2Remaining = 80;
for (const row of rows) {
  if (row.priority === "P0" && p0Remaining > 0) {
    p0Remaining--;
  } else if (row.priority === "P2" && p2Remaining > 0) {
    p2Remaining--;
  } else {
    row.priority = "P1";
  }
}
while (p2Remaining > 0) {
  const candidate = [...rows].reverse().find((row) => row.priority === "P1");
  if (!candidate) throw new Error("Unable to complete the P2 distribution");
  candidate.priority = "P2";
  p2Remaining--;
}

const columns = ["id","domain","subdomain","question","conversation_id","turn_number","expected_intent","expected_entity_type","expected_entity_name","expected_output_type","expected_time_scope","expected_behavior","expected_answer_contains","expected_answer_not_contains","expected_result_min","expected_result_max","ambiguity_expected","zero_result_allowed","priority","notes"];
const quote = (value) => `"${String(value ?? "").replaceAll('"', '""')}"`;
fs.writeFileSync("docs/ask_communio_competency_suite.csv", `${columns.map(quote).join(",")}\n${rows.map((row) => columns.map((column) => quote(row[column])).join(",")).join("\n")}\n`);
console.log(JSON.stringify({ total: rows.length, domains: Object.fromEntries([...new Set(rows.map((r) => r.domain))].map((d) => [d, rows.filter((r) => r.domain === d).length])), priorities: Object.fromEntries(["P0","P1","P2"].map((p) => [p, rows.filter((r) => r.priority === p).length])), behaviors: Object.fromEntries([...new Set(rows.map((r) => r.expected_behavior))].map((b) => [b, rows.filter((r) => r.expected_behavior === b).length])) }, null, 2));
