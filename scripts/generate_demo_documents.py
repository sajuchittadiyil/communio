from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)

OUT = Path(__file__).resolve().parents[1] / "assets" / "demo_documents"
NAVY = colors.HexColor("#0E2F6B")
GOLD = colors.HexColor("#D4AF37")
INK = colors.HexColor("#1D2939")
MUTED = colors.HexColor("#596579")
PALE = colors.HexColor("#F7F9FC")

DOCS = [
    ("annual_province_report_2025_26.pdf", "Annual Province Report 2025-26", [
        ("Provincial overview", "This fictional annual review presents a concise demonstration of Province life, mission and administration for Communio. It is not an authentic report of any congregation."),
        ("Current snapshot", "The Communio demo dataset records 113 active members, 12 communities and 21 ministries. These figures are included solely to demonstrate structured institutional reporting."),
        ("Communities and ministries", "Communities sustained prayer, hospitality and local coordination. Education, pastoral care, health and social outreach ministries continued their ordinary service."),
        ("Formation and governance", "Formation accompaniment emphasized discernment, human maturity and community life. Province governance focused on visitation, policy review and responsible recordkeeping."),
        ("Priorities for 2026-27", "Strengthen mission planning; support formators and local leaders; improve safeguarding formation; and deepen digital institutional memory through Communio."),
    ]),
    ("provincial_council_minutes_2026_08_20.pdf", "Provincial Council Minutes - 20 August 2026", [
        ("Meeting", "Demo meeting held at the Provincial House on 20 August 2026. Attendance: Provincial, Council members, Secretary and Bursar. All names and decisions are demonstration data."),
        ("Agenda", "Community visitation calendar; formation-house review; education commission update; policy publication; and strategic-plan monitoring."),
        ("Matters discussed", "The Council reviewed scheduled visitations, routine formation accompaniment, ministry reporting quality and the need for consistent archive metadata."),
        ("DEMO decisions", "Approve the demonstration visitation calendar; receive the formation report; circulate safeguarding reminders; and pilot the Communio document archive."),
        ("Action items", "Secretary: publish demo minutes. Bursar: prepare illustrative quarterly summary. Councillors: review assigned action notes before the next demo meeting."),
    ]),
    ("provincial_circular_august_2026.pdf", "Provincial Circular - August 2026", [
        ("Message from the Provincial", "Dear confreres, this fictional circular accompanies the Communio demonstration and highlights communion, mission and faithful stewardship."),
        ("Appointments", "Routine demo appointment information is recorded through Communio. No item in this circular constitutes a real ecclesial or personnel appointment."),
        ("Upcoming meetings", "Provincial Council, Education Commission and local leadership meetings appear in the demo calendar for coordinated planning."),
        ("Visitation and formation", "Communities are invited to prepare concise ministry updates. Formation houses are reminded to maintain regular accompaniment and evaluation records."),
        ("Closing", "May our common prayer renew generosity in mission. With fraternal greetings and gratitude for every service."),
    ]),
    ("province_strategic_plan_2026_2030.pdf", "Province Strategic Plan 2026-2030", [
        ("Mission vitality", "Renew community discernment and align ministries with emerging pastoral and social needs."),
        ("Formation", "Support integrated human, spiritual, intellectual and pastoral formation with well-prepared teams."),
        ("Education and pastoral ministry", "Strengthen values-based education, collaborative parish service and responsible local leadership."),
        ("Social outreach and sustainability", "Promote dignified service, ecological responsibility, prudent finance and long-term property planning."),
        ("Governance and digital memory", "Use clear policies, accountable reviews and Communio records to preserve decisions, reports and institutional learning."),
    ]),
    ("budakata_community_report_2025_26.pdf", "Budakata Mission Community Annual Report 2025-26", [
        ("Community identity", "Budakata Mission Community (demo code COM013) is presented as a mission community supporting prayer, fraternity and local service."),
        ("Residents and leadership", "Current residents and leadership are resolved by Communio from live demo assignments; this PDF intentionally avoids freezing personal data."),
        ("Ministries", "The community supports education, pastoral presence, health outreach and community engagement represented in the demonstration dataset."),
        ("Activities", "Common prayer, local coordination, school accompaniment, pastoral visits and community outreach shaped the sample year."),
        ("Opportunities and priorities", "Improve shared planning, strengthen local partnerships, maintain safeguarding awareness and submit concise annual records."),
    ]),
    ("budakata_school_report_2025_26.pdf", "Budakata School Annual Report 2025-26", [
        ("School profile", "Budakata School (demo code MIN015) represents a values-based education ministry established in the Communio demo dataset."),
        ("Educational mission", "The fictional programme supports accessible learning, attentive formation and opportunities for student participation and growth."),
        ("Academic and co-curricular life", "Teachers used collaborative planning, student activities, sports and cultural programmes to encourage holistic development."),
        ("Community engagement", "Parent communication and local partnerships supported attendance, wellbeing and shared responsibility for learning."),
        ("Priorities", "Strengthen teacher development, safeguarding practice, learning review and responsible maintenance planning."),
    ]),
    ("province_formation_report_2025_26.pdf", "Province Formation Annual Report 2025-26", [
        ("Formation overview", "This demo report covers candidates, novices, temporary professed and perpetual professed members in formation without identifying individuals."),
        ("Candidates and novices", "Initial formation emphasized discernment, self-knowledge, prayer, healthy relationships and readiness for religious commitment."),
        ("Professed in formation", "Temporary and perpetual professed members in study received community accompaniment and regular formation conversations."),
        ("Formation staff", "The demo Formation Staff group includes legitimate current formation responsibilities resolved from institutional assignments."),
        ("Priorities", "Develop formator support, consistent evaluations, safeguarding formation, intercultural competence and integrated pastoral exposure."),
    ]),
    ("child_safeguarding_policy_2026.pdf", "Child Safeguarding Policy 2026", [
        ("Purpose and status", "This general demonstration policy promotes safe ministry practice. It is not legal advice, certification or a substitute for applicable law and professional guidance."),
        ("Scope", "The sample expectations apply to members, employees, volunteers, students and visitors engaged in Province activities involving children."),
        ("Code of conduct", "Maintain appropriate boundaries, use observable settings, avoid favoritism, communicate responsibly and follow approved supervision practices."),
        ("Reporting and response", "Concerns should be reported promptly through authorized channels. Immediate safety takes priority; records must be factual, secure and access-controlled."),
        ("Training and recordkeeping", "Provide induction and refresher learning, document attendance, review procedures regularly and retain records according to approved schedules."),
    ]),
    ("personnel_appointment_circular_august_2026.pdf", "Personnel & Appointment Circular - August 2026", [
        ("Purpose", "This fictional circular demonstrates structured communication of benign personnel movements and appointments already represented in the Communio demo environment."),
        ("Appointment overview", "Current office, community and ministry assignments remain governed by their structured records and effective dates. This PDF does not create or amend assignments."),
        ("Transitions", "Local leaders are asked to support orderly handover notes, hospitality and access to the information required for each assigned service."),
        ("Record accuracy", "Members should report factual corrections through authorized administrative channels so current and historical records remain distinct."),
        ("Closing note", "The Province thanks each member for generous availability and invites communities to accompany transitions with prayer."),
    ]),
    ("province_financial_summary_2025_26.pdf", "Province Financial Summary 2025-26", [
        ("Important notice", "All values below are DEMONSTRATION FIGURES. This document is not an audited financial statement and does not represent real income, expenditure, assets or liabilities."),
        ("Illustrative operating summary", "Demo income: 12.40 million units. Demo programme expenditure: 8.15 million. Demo administration: 1.20 million. Demo maintenance: 1.05 million."),
        ("Illustrative allocation", "Formation 18%; education and pastoral programmes 34%; social outreach 16%; community support 20%; governance and administration 12%."),
        ("Stewardship observations", "Use consistent classifications, timely reconciliations, documented approvals and periodic ministry review."),
        ("Next-period priorities", "Improve budget narratives, asset registers, policy renewal tracking and consolidated demonstration reporting."),
    ]),
]


class DemoDocTemplate(BaseDocTemplate):
    def __init__(self, filename, title):
        self.document_title = title
        super().__init__(filename, pagesize=A4, rightMargin=18*mm, leftMargin=18*mm,
                         topMargin=25*mm, bottomMargin=20*mm)
        frame = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="body")
        self.addPageTemplates(PageTemplate(id="communio", frames=frame, onPage=self._page))

    def _page(self, canvas, doc):
        canvas.saveState()
        canvas.setFillColor(NAVY)
        canvas.rect(0, A4[1]-16*mm, A4[0], 16*mm, fill=1, stroke=0)
        canvas.setFillColor(GOLD)
        canvas.rect(0, A4[1]-17.5*mm, A4[0], 1.5*mm, fill=1, stroke=0)
        canvas.setFont("Helvetica-Bold", 9)
        canvas.setFillColor(colors.white)
        canvas.drawString(18*mm, A4[1]-10.5*mm, "COMMUNIO  |  INSTITUTIONAL MEMORY")
        canvas.setStrokeColor(colors.HexColor("#D0D5DD"))
        canvas.line(18*mm, 14*mm, A4[0]-18*mm, 14*mm)
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(MUTED)
        canvas.drawString(18*mm, 9.5*mm, "DEMO DOCUMENT - Communio demonstration data")
        canvas.drawRightString(A4[0]-18*mm, 9.5*mm, f"Page {doc.page}")
        canvas.restoreState()


def create_pdf(filename, title, sections):
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("Title", parent=styles["Title"], fontName="Helvetica-Bold",
                                 fontSize=23, leading=27, textColor=NAVY, alignment=TA_CENTER,
                                 spaceAfter=8*mm)
    demo_style = ParagraphStyle("Demo", parent=styles["Normal"], fontName="Helvetica-Bold",
                                fontSize=10, leading=13, textColor=colors.HexColor("#9A6B00"),
                                alignment=TA_CENTER, spaceAfter=8*mm)
    heading = ParagraphStyle("Heading", parent=styles["Heading2"], fontName="Helvetica-Bold",
                             fontSize=15, leading=19, textColor=NAVY, spaceBefore=4*mm, spaceAfter=3*mm)
    body = ParagraphStyle("Body", parent=styles["BodyText"], fontName="Helvetica",
                          fontSize=10.5, leading=16, textColor=INK, spaceAfter=5*mm)
    small = ParagraphStyle("Small", parent=body, fontSize=9, leading=13, textColor=MUTED)
    doc = DemoDocTemplate(str(OUT / filename), title)
    story = [Spacer(1, 8*mm), Paragraph(title, title_style),
             Paragraph("DEMO DOCUMENT | Communio demonstration data", demo_style),
             Table([["Document status", "Fictional demonstration record"],
                    ["Prepared for", "Communio Province Management demo"],
                    ["Confidentiality", "Demonstration only - no authentic records"]],
                   colWidths=[42*mm, 105*mm], style=TableStyle([
                       ("BACKGROUND", (0,0), (0,-1), PALE), ("TEXTCOLOR", (0,0), (0,-1), NAVY),
                       ("FONTNAME", (0,0), (0,-1), "Helvetica-Bold"),
                       ("FONTNAME", (1,0), (1,-1), "Helvetica"),
                       ("FONTSIZE", (0,0), (-1,-1), 9), ("LEADING", (0,0), (-1,-1), 13),
                       ("GRID", (0,0), (-1,-1), .5, colors.HexColor("#D0D5DD")),
                       ("VALIGN", (0,0), (-1,-1), "TOP"), ("PADDING", (0,0), (-1,-1), 7),
                   ])), Spacer(1, 10*mm),
             Paragraph("About this demonstration", heading),
             Paragraph("This original sample document illustrates how Communio can preserve reports, decisions, policies and institutional context. It contains no confidential or authentic congregation records.", body),
             PageBreak()]
    for index, (name, text) in enumerate(sections):
        story += [Paragraph(name, heading), Paragraph(text, body)]
        if index == 2:
            story += [PageBreak()]
    story += [Spacer(1, 5*mm), Paragraph("Demonstration record note", heading),
              Paragraph("Dates, figures, activities and decisions in this file exist only for product demonstration. Authoritative records require approval, controlled access and appropriate retention procedures.", small)]
    doc.build(story)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for item in DOCS:
        create_pdf(*item)
    print(f"Generated {len(DOCS)} PDFs in {OUT}")
