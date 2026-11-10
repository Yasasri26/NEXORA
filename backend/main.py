
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import fitz
import re

app = FastAPI(title="NEXORA AI Resume Analyzer")

# Allow our Flutter web application to communicate with the API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8000",
        "https://yasasri26.github.io",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MAX_FILE_SIZE = 10 * 1024 * 1024

# Initial skills dictionary.
SKILLS = [
    "Python", "Java", "C", "C++", "JavaScript", "Dart",
    "Flutter", "React", "HTML", "CSS",
    "Machine Learning", "Deep Learning", "Artificial Intelligence",
    "Data Science", "NLP", "Computer Vision",
    "TensorFlow", "PyTorch", "Scikit-learn",
    "Pandas", "NumPy", "Matplotlib",
    "SQL", "MySQL", "PostgreSQL", "MongoDB",
    "FastAPI", "Flask", "Django",
    "Git", "GitHub", "Docker", "AWS", "Azure",
    "Linux", "REST API", "Data Structures",
    "Algorithms", "Cybersecurity"
]

# Health check
@app.get("/")
def home():
    return {
        "message": "Welcome to NEXORA AI",
        "status": "Backend is running"
    }


@app.get("/health")
def health():
    return {"status": "healthy"}


# Extract skills from resume text.
def extract_skills(text):
    found = []

    for skill in SKILLS:
        pattern = r"(?<!\w)" + re.escape(skill) + r"(?!\w)"

        if re.search(pattern, text, re.IGNORECASE):
            found.append(skill)

    return sorted(found)


# Identify important resume sections.
def identify_sections(text):
    lower_text = text.lower()

    section_keywords = {
        "Education": ["education", "academic background"],
        "Experience": ["experience", "work history", "employment"],
        "Projects": ["projects", "personal projects"],
        "Skills": ["skills", "technical skills", "technologies"],
        "Certifications": ["certifications", "certificates"]
    }

    found = []

    for section, keywords in section_keywords.items():
        if any(word in lower_text for word in keywords):
            found.append(section)

    return found


# Calculate a preliminary resume quality score.
def calculate_score(text, skills, sections):
    score = 0

    # Resume section completeness: maximum 50 points.
    score += min(len(sections) * 10, 50)

    # Relevant skills: maximum 30 points.
    score += min(len(skills) * 3, 30)

    # Resume content length: maximum 20 points.
    word_count = len(text.split())

    if word_count >= 300:
        score += 20
    elif word_count >= 150:
        score += 15
    elif word_count >= 75:
        score += 10
    elif word_count >= 30:
        score += 5

    return min(score, 100)


# Main resume analysis endpoint.
@app.post("/analyze-resume")
async def analyze_resume(file: UploadFile = File(...)):

    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Please upload a PDF resume."
        )

    content = await file.read(MAX_FILE_SIZE + 1)

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail="Resume must be smaller than 10 MB."
        )

    if not content.startswith(b"%PDF-"):
        raise HTTPException(
            status_code=400,
            detail="The uploaded file is not a valid PDF."
        )

    try:
        document = fitz.open(
            stream=content,
            filetype="pdf"
        )

        if document.page_count > 30:
            raise HTTPException(
                status_code=400,
                detail="Resume PDF cannot exceed 30 pages."
            )

        # Extract text from every page.
        extracted_text = ""

        for page in document:
            extracted_text += page.get_text() + "\n"

        page_count = document.page_count
        document.close()

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Unable to read this PDF. Please upload another PDF."
        )

    if not extracted_text.strip():
        raise HTTPException(
            status_code=422,
            detail="No readable text found. Scanned PDFs require OCR."
        )

    skills = extract_skills(extracted_text)
    sections = identify_sections(extracted_text)

    word_count = len(extracted_text.split())

    score = calculate_score(
        extracted_text,
        skills,
        sections
    )

    return {
        "success": True,
        "filename": file.filename,
        "page_count": page_count,
        "word_count": word_count,
        "skills": skills,
        "skill_count": len(skills),
        "sections_found": sections,
        "section_count": len(sections),
        "resume_score": score,
        "score_type": "Preliminary heuristic quality score",
        "message": "Resume analysis completed successfully."
    }

from pydantic import BaseModel
from typing import List


# Skills required for different career roles
ROLE_SKILLS = {
    "AI/ML Engineer": [
        "Python", "Machine Learning", "Deep Learning",
        "NumPy", "Pandas", "Scikit-learn",
        "TensorFlow", "PyTorch", "SQL",
        "Statistics", "Data Structures", "Git",
        "Docker", "NLP", "Computer Vision"
    ],

    "Data Scientist": [
        "Python", "Statistics", "Machine Learning",
        "NumPy", "Pandas", "Matplotlib",
        "SQL", "Scikit-learn", "Deep Learning",
        "Data Visualization", "Power BI"
    ],

    "Data Analyst": [
        "Python", "SQL", "Excel", "Statistics",
        "Power BI", "Tableau", "Pandas",
        "Data Visualization", "NumPy"
    ],

    "Flutter Developer": [
        "Dart", "Flutter", "Firebase",
        "REST API", "Git", "OOP",
        "State Management", "SQL"
    ],

    "Cybersecurity Engineer": [
        "Python", "Linux", "Networking",
        "Cybersecurity", "Cryptography",
        "Wireshark", "Penetration Testing",
        "Ethical Hacking", "SQL", "Git"
    ]
}


class SkillGapRequest(BaseModel):
    skills: List[str]
    target_role: str


@app.post("/analyze-skill-gap")
def analyze_skill_gap(data: SkillGapRequest):

    if data.target_role not in ROLE_SKILLS:
        return {
            "error": "Unsupported career role"
        }

    required_skills = ROLE_SKILLS[data.target_role]

    # Normalize skill names for comparison
    user_skills = {skill.strip().lower() for skill in data.skills}

    matched_skills = [
        skill for skill in required_skills
        if skill.lower() in user_skills
    ]

    missing_skills = [
        skill for skill in required_skills
        if skill.lower() not in user_skills
    ]

    total_skills = len(required_skills)

    match_percentage = round(
        (len(matched_skills) / total_skills) * 100
    )

    high_priority = missing_skills[:3]
    medium_priority = missing_skills[3:6]
    low_priority = missing_skills[6:]

    return {
        "target_role": data.target_role,
        "match_percentage": match_percentage,
        "matched_skills": matched_skills,
        "missing_skills": missing_skills,
        "high_priority": high_priority,
        "medium_priority": medium_priority,
        "low_priority": low_priority,
        "total_required": total_skills
    }


# Personalized learning roadmap generation
ROADMAP_TOPICS = {
    "Python": "Core syntax, functions, OOP, modules and practical scripting",
    "Machine Learning": "Supervised learning, unsupervised learning and model evaluation",
    "Deep Learning": "Neural networks, backpropagation and deep learning workflows",
    "NumPy": "Arrays, vectorization and numerical operations",
    "Pandas": "Data cleaning, transformation and exploratory analysis",
    "Scikit-learn": "Preprocessing, pipelines, model training and evaluation",
    "TensorFlow": "Build, train and evaluate neural networks",
    "PyTorch": "Tensors, autograd, datasets and model training",
    "SQL": "Joins, aggregations, subqueries and database design",
    "Statistics": "Probability, distributions, hypothesis testing and inference",
    "Data Structures": "Arrays, linked lists, stacks, queues, trees and graphs",
    "Git": "Branches, commits, pull requests and collaboration",
    "Docker": "Images, containers, Dockerfiles and deployment basics",
    "NLP": "Text preprocessing, embeddings and language models",
    "Computer Vision": "Image processing, CNNs and object detection",
    "Matplotlib": "Charts, plots and communicating data insights",
    "Data Visualization": "Dashboard design and visual storytelling",
    "Power BI": "Data modeling, DAX and interactive reports",
    "Excel": "Formulas, lookup functions, pivot tables and charts",
    "Tableau": "Data connections, calculated fields and dashboards",
    "Dart": "Dart syntax, OOP, asynchronous programming and null safety",
    "Flutter": "Widgets, layouts, navigation and state management",
    "Firebase": "Authentication, Firestore and app integration",
    "REST API": "HTTP methods, JSON, API integration and error handling",
    "OOP": "Encapsulation, inheritance, abstraction and polymorphism",
    "State Management": "Provider, Riverpod or Bloc fundamentals",
    "Linux": "Shell commands, permissions, processes and networking tools",
    "Networking": "TCP/IP, DNS, HTTP, routing and network troubleshooting",
    "Cybersecurity": "Security fundamentals, threat modeling and defensive practices",
    "Cryptography": "Hashing, encryption, keys and digital signatures",
    "Wireshark": "Capture filters, display filters and packet analysis",
    "Penetration Testing": "Authorized testing methodology and vulnerability reporting",
    "Ethical Hacking": "Reconnaissance, security assessment and responsible disclosure",
}

class RoadmapRequest(BaseModel):
    skills: List[str]
    target_role: str

@app.post("/generate-roadmap")
def generate_roadmap(data: RoadmapRequest):
    if data.target_role not in ROLE_SKILLS:
        raise HTTPException(status_code=400, detail="Unsupported career role")

    user_skills = {skill.strip().lower() for skill in data.skills}
    missing = [skill for skill in ROLE_SKILLS[data.target_role]
               if skill.lower() not in user_skills]
    weekly_plan = []

    for start in range(0, len(missing), 3):
        week_skills = missing[start:start + 3]
        topics = [{
            "skill": skill,
            "topic": ROADMAP_TOPICS.get(skill, f"Learn the fundamentals and practical use of {skill}"),
            "project": f"Build a small practical exercise using {skill}"
        } for skill in week_skills]
        weekly_plan.append({
            "week": start // 3 + 1,
            "title": f"Week {start // 3 + 1}: Build your skills",
            "topics": topics,
            "project": f"Create a mini-project applying {week_skills[0]}"
        })

    return {
        "target_role": data.target_role,
        "total_weeks": len(weekly_plan),
        "total_missing_skills": len(missing),
        "weekly_plan": weekly_plan,
        "message": "Your personalized learning roadmap is ready."
    }

# ---------------- JOB MATCHING ----------------
class JobMatchRequest(BaseModel):
    skills: List[str] = []
    target_role: str


SAMPLE_JOBS = {
    "AI/ML Engineer": [
        {"title": "Junior AI/ML Engineer", "company": "Sample Technology Team", "location": "India · Hybrid", "description": "Build data pipelines, train models and evaluate machine-learning solutions.", "skills": ["Python", "Machine Learning", "Pandas", "Scikit-learn", "SQL", "Git"]},
        {"title": "Computer Vision Associate", "company": "Sample Vision Labs", "location": "India · Remote", "description": "Prototype image-processing and object-detection workflows.", "skills": ["Python", "Computer Vision", "Deep Learning", "PyTorch", "NumPy", "Docker"]},
        {"title": "NLP Engineering Trainee", "company": "Sample Applied AI", "location": "India · Hybrid", "description": "Work on text processing, embeddings and language-model applications.", "skills": ["Python", "NLP", "Machine Learning", "SQL", "Git", "Docker"]},
    ],
    "Data Scientist": [
        {"title": "Associate Data Scientist", "company": "Sample Analytics Group", "location": "India · Hybrid", "description": "Explore datasets, build predictive models and communicate findings.", "skills": ["Python", "Statistics", "Machine Learning", "Pandas", "SQL", "Scikit-learn"]},
        {"title": "Applied Data Science Trainee", "company": "Sample Insights", "location": "India · Remote", "description": "Create experiments, visualizations and baseline prediction models.", "skills": ["Python", "NumPy", "Matplotlib", "Deep Learning", "Statistics"]},
    ],
    "Data Analyst": [
        {"title": "Junior Data Analyst", "company": "Sample Business Intelligence", "location": "India · Hybrid", "description": "Query business data and build dashboards for stakeholders.", "skills": ["SQL", "Excel", "Power BI", "Statistics", "Python", "Data Visualization"]},
        {"title": "Reporting Analyst Trainee", "company": "Sample Operations", "location": "India · On-site", "description": "Prepare recurring reports and validate data quality.", "skills": ["Excel", "SQL", "Tableau", "Pandas"]},
    ],
    "Flutter Developer": [
        {"title": "Flutter Developer Intern", "company": "Sample Mobile Studio", "location": "India · Hybrid", "description": "Build responsive cross-platform applications and integrate APIs.", "skills": ["Dart", "Flutter", "REST API", "Git", "Firebase", "OOP"]},
        {"title": "Mobile App Engineering Trainee", "company": "Sample AppWorks", "location": "India · Remote", "description": "Implement app screens, state management and backend integration.", "skills": ["Flutter", "Dart", "State Management", "REST API", "SQL"]},
    ],
    "Cybersecurity Engineer": [
        {"title": "Security Analyst Trainee", "company": "Sample Security Operations", "location": "India · Hybrid", "description": "Assist with defensive monitoring, packet analysis and security reporting.", "skills": ["Linux", "Networking", "Cybersecurity", "Wireshark", "Python", "Git"]},
        {"title": "Junior Application Security Associate", "company": "Sample AppSec Group", "location": "India · Remote", "description": "Review application risks and document secure-development findings.", "skills": ["Python", "Cybersecurity", "Cryptography", "SQL", "Linux"]},
    ],
}

@app.post("/match-jobs")
def match_jobs(data: JobMatchRequest):
    if data.target_role not in SAMPLE_JOBS:
        raise HTTPException(status_code=400, detail="Unsupported career role")
    user = {s.strip().lower() for s in data.skills if s.strip()}
    jobs = []
    for job in SAMPLE_JOBS[data.target_role]:
        matched = [s for s in job["skills"] if s.lower() in user]
        missing = [s for s in job["skills"] if s.lower() not in user]
        score = round(100 * len(matched) / len(job["skills"])) if job["skills"] else 0
        jobs.append({**job, "matched_skills": matched, "missing_skills": missing, "match_percentage": score})
    jobs.sort(key=lambda x: x["match_percentage"], reverse=True)
    return {"target_role": data.target_role, "jobs": jobs, "is_live_listing": False, "message": "Illustrative role matches generated from your skills."}


# ---------------- INTERVIEW PRACTICE ----------------
class InterviewQuestionRequest(BaseModel):
    target_role: str
    question_type: str = "Technical"
    skills: List[str] = []


class InterviewAnswer(BaseModel):
    question: str
    answer: str


class InterviewEvaluateRequest(BaseModel):
    target_role: str
    answers: List[InterviewAnswer]


INTERVIEW_QUESTIONS = {
    "AI/ML Engineer": [
        "Explain the difference between supervised and unsupervised learning.",
        "How do you detect and reduce overfitting in a machine-learning model?",
        "What is the purpose of a train, validation and test split?",
        "Explain precision, recall and F1-score with an example.",
        "Describe a machine-learning project you built and the trade-offs you made.",
    ],
    "Data Scientist": [
        "How would you handle missing values and outliers in a dataset?",
        "Explain the bias-variance trade-off.",
        "When would you choose a median over a mean?",
        "How would you explain a model's result to a non-technical stakeholder?",
        "Describe how you would design an experiment to test a hypothesis.",
    ],
    "Data Analyst": [
        "Explain the difference between INNER JOIN and LEFT JOIN.",
        "How would you validate a dashboard before sharing it?",
        "What is the difference between correlation and causation?",
        "How would you investigate a sudden drop in a business metric?",
        "Describe a time you converted raw data into a useful insight.",
    ],
    "Flutter Developer": [
        "What is the difference between StatelessWidget and StatefulWidget?",
        "Explain how you manage asynchronous operations in Dart.",
        "How do you structure API calls and handle errors in Flutter?",
        "What is widget rebuilding and how can you avoid unnecessary rebuilds?",
        "Describe a Flutter application you developed and its architecture.",
    ],
    "Cybersecurity Engineer": [
        "Explain the CIA triad and give a practical example of each part.",
        "What is the difference between hashing and encryption?",
        "How would you investigate suspicious network traffic defensively?",
        "Explain the purpose of least privilege and multi-factor authentication.",
        "How would you prioritize and report a discovered vulnerability?",
    ],
}

HR_QUESTIONS = [
    "Tell me about yourself and the kind of role you are looking for.",
    "Describe a challenging project and how you handled the difficulties.",
    "Tell me about a time you received feedback and acted on it.",
    "How do you prioritize tasks when you have multiple deadlines?",
    "Why are you interested in this role, and what would you bring to the team?",
]

@app.post("/interview/questions")
def interview_questions(data: InterviewQuestionRequest):
    if data.target_role not in ROLE_SKILLS:
        raise HTTPException(status_code=400, detail="Unsupported career role")
    if data.question_type not in ["Technical", "HR"]:
        raise HTTPException(status_code=400, detail="Question type must be Technical or HR")
    questions = INTERVIEW_QUESTIONS[data.target_role] if data.question_type == "Technical" else HR_QUESTIONS
    return {"target_role": data.target_role, "question_type": data.question_type, "questions": [{"id": i + 1, "question": q} for i, q in enumerate(questions)]}


@app.post("/interview/evaluate")
def evaluate_interview(data: InterviewEvaluateRequest):
    if data.target_role not in ROLE_SKILLS:
        raise HTTPException(status_code=400, detail="Unsupported career role")
    if not data.answers:
        raise HTTPException(status_code=400, detail="Submit at least one answer")
    feedback = []
    scores = []
    for index, item in enumerate(data.answers, 1):
        words = len(item.answer.split())
        if words < 8:
            score = 20
            note = f"Answer {index}: Add more detail. Explain the concept, give an example and state the result."
        elif words < 25:
            score = 55
            note = f"Answer {index}: A useful start. Add a concrete example, reasoning and relevant terminology."
        else:
            score = 75
            note = f"Answer {index}: Good level of detail. Improve it with a clear structure, measurable outcome and concise conclusion."
        scores.append(score)
        feedback.append(note)
    average = round(sum(scores) / len(scores))
    summary = "Strong practice response length. Refine examples and clarity." if average >= 70 else "Good start. Add structured explanations and specific examples to strengthen your answers."
    return {"target_role": data.target_role, "score": average, "summary": summary, "feedback": feedback, "evaluation_type": "Rule-based answer-length guidance"}
