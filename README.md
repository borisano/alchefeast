# Problem statement

### _It's dinner time!_ Create an application that helps users find the most relevant recipes that they can prepare with the ingredients that they have at home

## Objective

Deliver a prototype web application to answer the above problem statement.

__✅ Must have's__

- A back-end with Ruby on Rails (If you don't know Ruby on Rails, refer to the FAQ)
- A SQL-compliant relational database
- A well-thought user experience

__🚫 Don'ts__

- Excessive effort in styling
- Features which don't directly answer the above statement
- Over-engineer your prototype

## Deliverable

- The codebase should be pushed on the current GitHub private repository.
- 2 or 3 user stories that address the statement in your repo's `README.md`.
- The application accessible online (a personal server, fly.io or something else).
- Submission of the above via [this form](https://forms.gle/siH7Rezuq2V1mUJGA).
- If you're on Mac, make sure your browser has [permission to share the screen](https://support.apple.com/en-al/guide/mac-help/mchld6aa7d23/mac).

## User Stories

### 1. As a home cook, I want to search for recipes using ingredients I have at home, so that I can decide what to cook without making a grocery trip.

**Acceptance Criteria:**
- I can enter multiple ingredients separated by commas
- The system shows me recipes that use those ingredients
- I can choose to find recipes with ALL or ANY of my ingredients
- Search results show recipe details like cooking time and ratings

### 2. As a busy person, I want to quickly browse recipes by category and see essential information at a glance, so that I can make quick cooking decisions.

**Acceptance Criteria:**
- I can view all recipes in an organized grid layout
- I can filter recipes by category (Italian, Indian, etc.)
- Each recipe card shows key information: time, rating, category
- I can click to view full recipe details including ingredient list

### 3. As someone looking for cooking inspiration, I want to discover new recipes through featured content and popular ingredients, so that I can try something different.

**Acceptance Criteria:**
- The homepage shows featured recipes to inspire me
- I can see popular ingredients used across recipes
- I can click on popular ingredients to find related recipes
- The interface guides me from inspiration to actionable cooking plans

### 4. As a home cook who wants detailed guidance, it would not be enough for me to just get a list of ingredients. I need to be able to get detailed instructions on how to cook the dish. AI should be leveraged in order to acheive it

**Acceptance Criteria:**
- I can request AI cooking advice for any recipe by clicking "Ask Alchemist for how to cook it"
- The AI provides detailed step-by-step cooking instructions tailored to the recipe
- The AI includes helpful cooking tips, techniques, and timing advice
- For recipes that already have AI instructions, I can access them via "Check out Alchemist cooking advice" 
- The AI advice is stored and can be viewed again without re-generating, to conserve usage tokens
- The interface clearly shows which recipes have AI cooking steps available

## Data

Please start from the following dataset to perform the assignment:
[english-language recipes](https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz) scraped from www.allrecipes.com with [recipe-scrapers](https://github.com/hhursev/recipe-scrapers)

Download it with this command if the above link doesn't work:
```sh textWrap
wget https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz && gzip -dc recipes-en.json.gz > recipes-en.json
```

## FAQ

<details>
<summary><i>I'm a back-end developer or don't know React, what do I do?</i></summary>

Just make the simplest UI, style isn't important and server rendered HTML pages will do!
</details>

<details>
<summary><i>Can I have a time extension for the test?</i></summary>

No worries, we know that unforeseen events happen, simply reach out to the recruiter you've been
talking with to discuss this.
</details>

<details>
<summary><i>Can I transform the dataset before seeding it in the DB</i></summary>

Absolutely, feel free to post-process the dataset as needed to fit your needs.
</details>

<details>
<summary><i>Should I rather implement option X or option Y</i></summary>

That decision is up to you and part of the challenge. Please document your choice
to be able to explain your reflexion and choice to your interviewer for the
challenge debrief.
</details>

<details>
<summary><i>I tried to make it available online but can't make it work</i></summary>

Don't overinvest time (or money) on this if you really can't figure it out and we'll
assess over your local version. Please make sure everything is working smoothly
locally before your debrief interview.
</details>

<details>
<summary><i>I don't know <b>Ruby on Rails</b></i></summary>

That probably means you're applying for a managerial position, so it's fine to
pick another language of your choice to perform this task.
</details>
