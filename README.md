# Contributing to this Blog

**IMPORTANT:** Please only pull request this repository if you have already been invited or approved by the data.table community team, or if you are proposing a new Seal of Approval package by following the template.
If you would like to propose a guest blog post, email r.data.table@gmail.com and we will get back to you shortly.

1. Fork this repository.

2. In the `posts` directory, copy the a folder corresponding to your anticipated blog post. It should use the form
   `YYYY-MM-DD-post_title-author_name`, where the date is the anticipated date of publication, the title is an
   abbreviated version of your topic, and the name is yours.

3. Copy the `posts/2023-10-02-post-template/index.qmd` into your newly created directory.  **Do not rename this file!**

4. Open your new `YYYY-MM-DD-post_title-author_name/index.qmd` that you have just copied and edit the header. You should
   change the `title`, `date` and `author` fields. If you wish to add a picture to the post add it to the directory and rename
   it `ìmage.jpg`.

```yaml
---
title: "Guest Post on The Raft"
author: "A.N.Other"
date: "2023-10-18"
categories: [news, code, analysis]
image: "image.jpg"
draft: true
---
```

5. In the body of `index.qmd`, compose your blog post.

```` markdown
This is a post with executable code.

```{r}
1 + 1
```

````

6. Render your document only (not the full quarto project) to preview it.

7. When you are finished, stage, commit and push your `index.qmd` and `image.jpg` only, do **NOT** include any of the
   built files (they should be ignored by git automatically though).

8. Your fork on GitHub will now be ahead of the `rdatatable-community/The-Raft` from which you've branched and you
   should see the option to `Contribute`. Doing so will create a Pull Request, once merged the post will be published in
   due course.
