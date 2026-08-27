import { canonicalRole, currentAppointmentCompliance, eligibilityStatus, isRestrictedProfileQuestion, qualificationMatches } from "./wave3_query_logic.ts";

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

Deno.test("Wave 3 qualification aliases use structured qualification fields", () => {
  assert(qualificationMatches({ qualification: "Master of Theology" }, "theology masters"), "theology master's alias failed");
  assert(qualificationMatches({ degree: "B.Th." }, "BTh"), "BTh abbreviation failed");
  assert(qualificationMatches({ qualification_name: "Diploma", specialization: "Formation" }, "formation diploma"), "formation diploma composition failed");
  assert(!qualificationMatches({ qualification: "MBA", specialization: "Finance" }, "theology masters"), "unrelated degree matched");
});

Deno.test("Wave 3 role aliases remain canonical", () => {
  assert(canonicalRole("Formation Director") === "formation_director", "formation director alias failed");
  assert(canonicalRole("Provincial Treasurer") === "provincial_bursar", "treasurer alias failed");
  assert(canonicalRole("School Principal") === "principal", "principal alias failed");
});

Deno.test("Wave 3 eligibility statuses preserve conditional and unevaluated", () => {
  assert(eligibilityStatus({ eligibility_status: "ELIGIBLE" }) === "ELIGIBLE", "eligible failed");
  assert(eligibilityStatus({ eligibility_status: "CONDITIONAL" }) === "CONDITIONAL", "conditional collapsed");
  assert(eligibilityStatus({ eligibility_status: "NOT_ELIGIBLE" }) === "NOT ELIGIBLE", "not eligible failed");
  assert(eligibilityStatus({}) === "NOT EVALUATED", "missing evaluation was not preserved");
});

Deno.test("Wave 3 compliance joins current appointments to recorded evaluations", () => {
  const rows = currentAppointmentCompliance([
    { id: "a", member_id: "m1", office_type_code: "formation_director" },
    { id: "b", member_id: "m2", office_type_code: "provincial" },
    { id: "c", member_id: "m3", office_type_code: "principal" },
  ], [
    { member_id: "m1", role_code: "formation_director", eligibility_status: "ELIGIBLE", eligibility_reason: "Recorded criteria met" },
    { member_id: "m2", role_code: "provincial", eligibility_status: "NOT_ELIGIBLE", eligibility_reason: "Recorded criterion not met" },
  ]);
  assert(rows[0].compliance_status === "COMPLIANT", "eligible appointment was not compliant");
  assert(rows[1].compliance_status === "NOT COMPLIANT", "ineligible appointment was not flagged");
  assert(rows[2].compliance_status === "NOT EVALUATED", "missing evaluation was collapsed into non-compliance");
  assert(rows[1].compliance_reason === "Recorded criterion not met", "recorded reason was lost");
});

Deno.test("Wave 3 restricted profile questions are denied without broad false positives", () => {
  for (const question of ["show Joseph's will", "open Joseph's digital safe", "show private documents", "show the personnel file"]) {
    assert(isRestrictedProfileQuestion(question), `${question} was not restricted`);
  }
  assert(!isRestrictedProfileQuestion("show Joseph's official email"), "authorized public contact was over-blocked");
  assert(!isRestrictedProfileQuestion("what qualifications does Joseph have"), "qualification was over-blocked");
});
