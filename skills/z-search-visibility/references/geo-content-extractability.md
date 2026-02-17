# GEO: Content Extractability Reference

How AI systems retrieve content and how to optimize your content for extraction into AI-generated answers.

---

## How AI Content Retrieval Works

AI systems generating answers (Google AI Overviews, ChatGPT with browsing, Perplexity) use Retrieval-Augmented Generation (RAG):

1. **Chunking**: Content is broken into passages (chunks)
2. **Embedding**: Chunks are converted into numerical vector representations
3. **Retrieval**: When a user asks a question, the system finds the most semantically relevant chunks
4. **Synthesis**: Retrieved chunks are assembled into a coherent answer, often combining passages from multiple sources

Critical implication: Your content is not consumed as a whole page. Individual passages are pulled out and used in isolation, without the surrounding context from your original page.

### Two Types of AI Knowledge

**Retrieval-based (real-time)**: Systems like Google AI Mode, Perplexity with grounding, and ChatGPT with browsing retrieve content in real-time per query. Content structure and extractability directly affect whether your content is used.

**Training-based (base model)**: What the LLM learned during pre-training. This comes from massive datasets, not per-query retrieval. Content structure matters less here. What matters is consistent, authoritative publishing over time that becomes part of training data.

This reference focuses primarily on retrieval-based optimization, as it is where structural changes have immediate impact.

---

## Core Extractability Principles

### 1. Self-Contained Paragraphs

Each paragraph should express one complete idea that makes sense without any surrounding context.

**Bad, context-dependent passages**:

"There are several reasons this method works. After trying it, most people find their results improve. That's why many experts recommend it."
Problem: What method? What results? What experts? Meaningless when extracted.

"As we discussed in the previous section, this approach has limitations."
Problem: References content the AI will not include.

"This is important because of what we covered above."
Problem: "What we covered above" does not exist in an AI answer.

**Good, self-contained passages**:

"Cold brew coffee steeps for 12-24 hours in cold water, producing a concentrate with 67% less acidity than hot-brewed coffee. This lower acidity makes it easier on the stomach and allows more subtle flavor notes to emerge."
Works: Complete concept. Technique, timeframe, result, and benefit all in one passage.

"The Mediterranean diet emphasizes whole grains, olive oil, fish, and vegetables while limiting red meat and processed foods. A 2023 meta-analysis of 12 studies found it reduces cardiovascular disease risk by 25%."
Works: Definition, components, and evidence in a single extractable unit.

### 2. Front-Loaded Information

Put the main point first. Supporting detail follows.

**Bad, buried answer**:

"Many people wonder about the best approach, and there are various schools of thought. Some experts suggest one thing, others another. After weighing the evidence from multiple clinical trials and considering various population demographics, the recommended daily protein intake for adults over 50 is 1.2g per kilogram of body weight."

**Good, front-loaded**:

"Adults over 50 should consume approximately 1.2g of protein per kilogram of body weight daily. This higher threshold, recommended by the European Society for Clinical Nutrition, compensates for age-related muscle loss (sarcopenia) and supports bone density maintenance."

The AI is more likely to extract the second version because the answer appears immediately.

### 3. Specific Facts Over Generalizations

AI systems preferentially extract concrete, verifiable information.

**Bad, vague**:
- "Many companies have seen success with this approach."
- "The market has grown significantly in recent years."
- "Experts generally recommend this technique."

**Good, specific**:
- "Shopify merchants using headless commerce saw a 35% improvement in page load times, according to Shopify's 2024 Commerce Report."
- "The global AI market grew from $136.6B in 2022 to $196.6B in 2023, a 44% year-over-year increase (IDC Worldwide AI Spending Guide)."
- "The American Heart Association recommends 150 minutes of moderate aerobic activity per week for cardiovascular health."

### 4. Descriptive Headings

Headings signal to AI systems what each section answers. Structure headings to match how users ask questions.

**Bad headings**:
- "Overview"
- "Details"
- "More Information"

**Good headings**:
- "What is the recommended daily water intake for adults?"
- "How does intermittent fasting affect metabolism?"
- "Best CRM software for small businesses in 2025"
- "PostgreSQL vs MySQL: key differences for enterprise development"

### 5. One Idea Per Paragraph

Do not combine multiple distinct concepts in a single paragraph. When AI retrieves a passage, it should get one clean idea, not a jumble of loosely related points.

---

## High-Value Extractable Content Patterns

### Definition Blocks

Format: "[Term] is [clear definition]. It [primary function/purpose]. Unlike [common confusion], it [key distinction]."

Example: "Server-side rendering (SSR) generates HTML on the server for each request, sending a fully rendered page to the browser. It improves initial load time and SEO compared to client-side rendering, where the browser must download and execute JavaScript before displaying content."

### Comparison Blocks

Format: "[Option A] [key differentiator] while [Option B] [contrasting characteristic]. Choose [A] when [use case]. Choose [B] when [alternative use case]."

Example: "PostgreSQL provides advanced features like JSON querying, full-text search, and complex joins, while MySQL offers simpler setup and faster read performance for straightforward queries. Choose PostgreSQL for complex data relationships and analytical workloads. Choose MySQL for high-volume read-heavy applications with simpler schemas."

### Process/How-To Blocks

Format: "To [achieve outcome], [step with specific detail]. [Expected result or why this works]."

Example: "To reduce Docker image size, use multi-stage builds that compile code in a build stage and copy only the final binary to a minimal runtime image like Alpine. This commonly reduces image sizes by 80-90%, cutting deployment times and reducing attack surface."

### Statistic/Data Blocks

Format: "[Specific finding] according to [source, date]. This represents [context or comparison]."

Example: "Global e-commerce sales reached $6.3 trillion in 2024, according to eMarketer's annual forecast. This represents a 9.4% year-over-year increase and accounts for 21.2% of total retail sales worldwide."

### Recommendation Blocks

Format: "[Product/approach] is best suited for [specific audience/use case] because [concrete reasons]. [Key differentiator from alternatives]."

Example: "Notion is best suited for small teams (under 50 people) that need a flexible workspace combining notes, databases, and project management. Its block-based editor allows non-technical users to build custom workflows without coding, though it can become slower with very large databases."

---

## Content Audit Checklist for Extractability

For each key page, assess:

- [ ] Can each important paragraph be understood without reading the rest of the page?
- [ ] Are answers front-loaded (main point first, then supporting detail)?
- [ ] Are specific facts, numbers, and sources included rather than vague claims?
- [ ] Do headings describe what the section answers (not just "Overview" or "Details")?
- [ ] Does each paragraph focus on one idea?
- [ ] Are there clear definition, comparison, or recommendation blocks for key topics?
- [ ] Is there minimal use of context-dependent phrases ("as mentioned above", "this is why", "see below")?
- [ ] Are statistics attributed to specific sources with dates?
- [ ] Could an AI extract any single paragraph and present it as a coherent, accurate answer?
