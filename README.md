# C4.2_Git

This project contains all versions of the "Language specific IDE" courses at OC, to foster collaboration between authors and the OC team.

## Confidentiality

This file describes internal OpenClassrooms course creation processes. They are for your eyes only if you have been given access. The file and its content should be kept confidential.

The course itself will be made available as CC-BY-SA when it is released. Please don't spoil the suspense before it is.

## Setup your environment

Please clone this project and open it in your favorite markdown editor.

> **:information_source:** A good markdown editor is *Visual Studio Code*  with the following extensions:
> 
> 1. GitLens, which supercharges the Git capabilities built into Visual Studio Code
> 2. Markdown All In One that provides keyboard shortcuts, table of contents, auto preview and more

## Create your branches

In order to write your course, please create 2 branches with the following syntax:

1. A *LANG_LANGUAGE_wip* branch for the day-to-day writing
2. A *LANG_LANGUAGE_review* branch where you will push content that is ready for review by the OC team

* *LANG* is either FR or EN
* *LANGUAGE* could be JAVA, DOTNET, PHP or whatever technology you are writing the course for.

## Write your content

* Your day to day writing should take place inside your *wip* (work in progress) branch. Please make your commits as granular as possible, as if you were coding.
* If the *outline.md* file is already written, please check it and discuss it with your Instructional Designer if you have comments / changes proposal. Otherwise, please create the file with the outline you propose.
* Write each file in a *PxCy.md_zzz* file, where:
    1. x is the part number
    2. y is the chapter number
    3. zzz is the chapter name

Read the sample.md file for all OC-specific markdown

## Send your content for review and mutualization

Each time you have content ready for review, please *push* it to your *review* branch.

You can create an *issue* and assign your Instructional Designer to it so that discussions can happen there. Specific changes will be proposed by the OC team through pull requests.

Once validated on a given *review* branch, content that can be mutualized between LANGUAGES can be proposed as a pull request to the *master* branch. This will make this content available to new authors whenever a new course for another LANGUAGE is started.

We can also discuss mutualized content between authors and the OC team through *issues*.

## How to provide code and active codevolve exercises?

* Prefer using codevolve for exercises. This allow the student to write code directly in the browser. Not having to install tools - or pushing the moment as far as possible - helps lower the churn rate. Write your codevolve exercises in a codevolve folder in this project and sync it to the platform using https://docs.codevolve.com/how-tos/github-file-sync.
* If an exercise or activity requires the Student getting some code to start with, create a folder in this project so we can make it available through GitHub.
