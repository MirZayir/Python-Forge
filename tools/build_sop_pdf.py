"""Generate a print-ready Statement of Purpose PDF.

Usage:
    python tools/build_sop_pdf.py [output.pdf]
"""

import sys
from pathlib import Path

from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    HRFlowable,
    KeepTogether,
    PageTemplate,
    Paragraph,
    Spacer,
)

class Profile:
    """Layout metrics. 'standard' reads comfortably; 'compact' fits one A4 page."""

    def __init__(
        self,
        margin: float,
        top: float,
        bottom: float,
        title_size: float,
        title_leading: float,
        body_size: float,
        body_leading: float,
        para_gap: float,
        sign_gap: float,
        show_footer: bool,
    ) -> None:
        self.margin = margin
        self.top = top
        self.bottom = bottom
        self.title_size = title_size
        self.title_leading = title_leading
        self.body_size = body_size
        self.body_leading = body_leading
        self.para_gap = para_gap
        self.sign_gap = sign_gap
        self.show_footer = show_footer


PROFILES = {
    "standard": Profile(
        margin=2.5 * cm,
        top=2.2 * cm,
        bottom=2.2 * cm,
        title_size=15.5,
        title_leading=19,
        body_size=11.5,
        body_leading=16.8,
        para_gap=10,
        sign_gap=18,
        show_footer=True,
    ),
    "compact": Profile(
        margin=2.2 * cm,
        top=1.9 * cm,
        bottom=1.7 * cm,
        title_size=14.5,
        title_leading=17,
        body_size=10.8,
        body_leading=14.5,
        para_gap=7.5,
        sign_gap=13,
        show_footer=False,
    ),
}

TITLE = "STATEMENT OF PURPOSE"

PARAGRAPHS = [
    "I am Mir Zayir Shabir, an MCA graduate from the Islamic University of Science and "
    "Technology (IUST), Awantipora, Jammu &amp; Kashmir. Having recently completed my final "
    "semester examinations, I am looking for an opportunity where I can move beyond academic "
    "learning and apply my technical knowledge to practical problems. The Chief Minister\u2019s "
    "Digital Internship Programme 2026 particularly interests me because of its focus on real "
    "government projects, digital services and emerging technologies.",

    "My primary area of interest is Mobile Application Development, particularly the development "
    "of applications that solve practical problems for users. During my MCA, I worked as part of a "
    "group on GoIUST, a cross-platform Smart University Bus Transport Management System developed "
    "using Flutter and Firebase. The project gave me an opportunity to understand how software can "
    "be designed around a real operational requirement rather than simply being developed as an "
    "academic exercise. It also strengthened my interest in building applications that can make "
    "services more accessible and efficient.",

    "Alongside academic projects, I have also worked independently on software projects to explore "
    "different areas of technology. PythonForge is a gamified Python learning application through "
    "which I explored Dart, Python, C++, and HTML. I have also worked on Z.Ai, an AI-powered "
    "personal operating system concept developed using Kotlin. These projects reflect my interest "
    "in experimenting with different technologies and understanding how they can be combined to "
    "create useful applications.",

    "Through the Chief Minister\u2019s Digital Internship Programme, I particularly hope to gain "
    "practical experience in Mobile Application Development and Government Applications (GovApps). "
    "I am also strongly interested in Artificial Intelligence and Machine Learning, Data Analytics "
    "and Cybersecurity. I believe that exposure to these areas within real government projects "
    "would help me understand how modern technologies can be applied responsibly to improve public "
    "services.",

    "Another reason I am interested in this programme is the opportunity to work under experienced "
    "mentors and collaborate with professionals on real problem statements. I want to improve not "
    "only my technical abilities but also my understanding of software development practices, "
    "testing, teamwork, documentation, problem analysis and delivering reliable solutions within "
    "real-world constraints.",

    "My academic background has provided me with a foundation in computer applications, while my "
    "projects have encouraged me to learn through experimentation and practical implementation. I "
    "now want to strengthen that foundation through meaningful professional exposure. I am "
    "particularly interested in contributing to projects where mobile technology, intelligent "
    "systems and digital services can make government processes more accessible and efficient for "
    "citizens.",

    "If selected, I would approach the internship with a willingness to learn, adapt to the "
    "assigned technology stack, work responsibly with mentors and team members, and contribute "
    "sincerely to the assigned project. My goal is to complete the programme not merely with an "
    "internship certificate, but with genuine experience in developing technology for real-world "
    "public-service challenges.",

    "The Chief Minister\u2019s Digital Internship Programme represents an opportunity for me to "
    "connect my academic background, software development experience and interest in emerging "
    "technologies with the practical needs of Jammu &amp; Kashmir. I believe this experience would "
    "be an important step in developing myself into a more capable and responsible technology "
    "professional.",
]

SIGNATURE_LINES = [
    "Mir Zayir Shabir",
    "MCA, Islamic University of Science and Technology",
    "Jammu &amp; Kashmir",
]


def _footer_drawer(profile: Profile):
    def draw(canvas, doc) -> None:
        if not profile.show_footer:
            return
        canvas.saveState()
        canvas.setFont("Times-Roman", 9)
        canvas.setFillGray(0.45)
        canvas.drawCentredString(A4[0] / 2.0, profile.bottom - 0.95 * cm, f"Page {doc.page}")
        canvas.restoreState()

    return draw


def build(output_path: Path, profile_name: str = "standard") -> None:
    profile = PROFILES[profile_name]

    doc = BaseDocTemplate(
        str(output_path),
        pagesize=A4,
        leftMargin=profile.margin,
        rightMargin=profile.margin,
        topMargin=profile.top,
        bottomMargin=profile.bottom,
        title="Statement of Purpose - Mir Zayir Shabir",
        author="Mir Zayir Shabir",
        subject="Chief Minister's Digital Internship Programme 2026",
        keywords="Statement of Purpose, Internship, MCA, IUST, Jammu and Kashmir",
    )

    # Zero frame padding so the printed text margins are exactly profile.margin.
    frame = Frame(
        profile.margin,
        profile.bottom,
        A4[0] - 2 * profile.margin,
        A4[1] - profile.top - profile.bottom,
        leftPadding=0,
        rightPadding=0,
        topPadding=0,
        bottomPadding=0,
        id="body",
    )
    doc.addPageTemplates(
        [PageTemplate(id="sop", frames=[frame], onPage=_footer_drawer(profile))]
    )

    title_style = ParagraphStyle(
        "SopTitle",
        fontName="Times-Bold",
        fontSize=profile.title_size,
        leading=profile.title_leading,
        alignment=TA_CENTER,
        spaceAfter=6,
        charSpace=1.1,
    )

    body_style = ParagraphStyle(
        "SopBody",
        fontName="Times-Roman",
        fontSize=profile.body_size,
        leading=profile.body_leading,
        alignment=TA_JUSTIFY,
        spaceAfter=profile.para_gap,
        firstLineIndent=0,
    )

    sign_name_style = ParagraphStyle(
        "SignName",
        parent=body_style,
        fontName="Times-Bold",
        alignment=0,
        spaceAfter=1,
    )

    sign_detail_style = ParagraphStyle(
        "SignDetail",
        parent=body_style,
        fontSize=profile.body_size - 1,
        leading=profile.body_leading - 2.8,
        alignment=0,
        spaceAfter=1,
    )

    story = [
        Paragraph(TITLE, title_style),
        HRFlowable(
            width="100%",
            thickness=0.7,
            color="#333333",
            spaceBefore=2,
            spaceAfter=profile.para_gap + 4,
        ),
    ]

    for para in PARAGRAPHS:
        story.append(Paragraph(para, body_style))

    story.append(Spacer(1, profile.sign_gap))
    story.append(
        KeepTogether(
            [Paragraph(SIGNATURE_LINES[0], sign_name_style)]
            + [Paragraph(line, sign_detail_style) for line in SIGNATURE_LINES[1:]]
        )
    )

    doc.build(story)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    profile = "compact" if "--compact" in sys.argv else "standard"
    target = Path(args[0]) if args else Path("Statement_of_Purpose_Mir_Zayir_Shabir.pdf")
    if target.parent != Path(""):
        target.parent.mkdir(parents=True, exist_ok=True)
    build(target, profile)
    print(f"Wrote {target.resolve()} [{profile}]")
