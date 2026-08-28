import {
  governanceLeaders,
  orderGovernanceMembers,
  resolveGovernanceBody,
} from "./governance_query_logic.ts";

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

const bodies = [
  {
    governance_body_id: "education",
    code: "EDUCATION_COMMISSION",
    name: "Education Commission",
    short_name: "Education",
  },
  {
    governance_body_id: "finance",
    code: "FINANCE_COMMISSION",
    name: "Finance Commission",
    short_name: "Finance",
  },
  {
    governance_body_id: "formation",
    code: "FORMATION_COMMISSION",
    name: "Formation Commission",
    short_name: "Formation",
  },
];

Deno.test("governance resolution honors exact names, safe aliases, codes, and IDs", () => {
  for (
    const query of [
      "Education Commission",
      "education committee",
      "EDUCATION_COMMISSION",
      "education",
      "education",
    ]
  ) {
    const result = resolveGovernanceBody(bodies, query);
    assert(
      result.kind === "match" && result.row.governance_body_id === "education",
      `failed ${query}`,
    );
  }
  const id = resolveGovernanceBody(bodies, "finance");
  assert(
    id.kind === "match" && id.row.governance_body_id === "finance",
    "ID resolution failed",
  );
});

Deno.test("governance resolution clarifies ambiguity and rejects unknown bodies", () => {
  assert(
    resolveGovernanceBody(bodies, "commission").kind === "ambiguous",
    "broad partial was guessed",
  );
  assert(
    resolveGovernanceBody(bodies, "property committee").kind === "missing",
    "unknown body matched",
  );
});

Deno.test("governance membership ordering uses explicit roles, never row order", () => {
  const ordered = orderGovernanceMembers([
    { display_name: "Member", role_code: "MEMBER" },
    { display_name: "President", role_code: "PRESIDENT" },
    { display_name: "Chair", role_code: "CHAIR" },
    { display_name: "Secretary", role_code: "SECRETARY" },
  ]);
  assert(
    ordered.map((row) => row.role_code).join(",") ===
      "CHAIR,PRESIDENT,SECRETARY,MEMBER",
    "role order incorrect",
  );
  assert(
    governanceLeaders(ordered).length === 2,
    "ordinary member treated as leader",
  );
});

Deno.test("governance evidence implementation uses only caller-authorized views", () => {
  const source = Deno.readTextFileSync(new URL("./index.ts", import.meta.url));
  const governanceSection = source.slice(
    source.indexOf("async function governanceDirectory"),
    source.indexOf("function officeCode"),
  );
  for (
    const view of [
      "v_governance_body_directory",
      "v_governance_body_current_members",
    ]
  ) {
    assert(governanceSection.includes(view), `missing ${view}`);
  }
  for (
    const privateSource of [
      'from("members")',
      "member_home_contacts",
      "date_of_birth",
      "service_role",
    ]
  ) {
    assert(
      !governanceSection.includes(privateSource),
      `private source leaked: ${privateSource}`,
    );
  }
  for (
    const label of [
      "Governance body",
      "Governance membership",
      "Governance leadership",
    ]
  ) {
    assert(
      governanceSection.includes(label),
      `missing evidence label ${label}`,
    );
  }
});
