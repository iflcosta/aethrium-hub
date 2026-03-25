"""
GitHub integration for Rafael (Lua) and Viktor (C++).
Creates a branch, commits the generated file, and opens a Pull Request.

Required env vars:
  GITHUB_TOKEN       — Personal Access Token with `repo` scope
  GITHUB_REPO        — Target repository, e.g. "iflcosta/baiak-thunder-86"
  GITHUB_BASE_BRANCH — Base branch for PRs (default: "main")
"""

import os
import asyncio
from typing import Optional

GITHUB_TOKEN       = os.getenv("GITHUB_TOKEN", "")
GITHUB_REPO        = os.getenv("GITHUB_REPO", "")
GITHUB_BASE_BRANCH = os.getenv("GITHUB_BASE_BRANCH", "main")


# ─── Internal helpers ─────────────────────────────────────────────────────────

def _is_configured() -> bool:
    return bool(GITHUB_TOKEN and GITHUB_REPO)


def _get_or_create_branch(repo, branch_name: str, base_sha: str):
    from github import GithubException
    try:
        repo.create_git_ref(ref=f"refs/heads/{branch_name}", sha=base_sha)
    except GithubException as e:
        if e.status != 422:  # 422 = already exists — silently accept
            raise


def _commit_file(repo, file_path: str, content: str, message: str, branch: str):
    from github import GithubException
    try:
        existing = repo.get_contents(file_path, ref=branch)
        repo.update_file(
            path=file_path,
            message=message,
            content=content,
            sha=existing.sha,
            branch=branch,
        )
    except GithubException:
        # File doesn't exist yet — create it
        repo.create_file(
            path=file_path,
            message=message,
            content=content,
            branch=branch,
        )


# ─── Public API ───────────────────────────────────────────────────────────────

async def push_lua_file(
    file_path: str,
    lua_code: str,
    task_id: str,
    task_title: str,
    pr_body: str = "",
) -> dict:
    """
    Commit a Lua file to a new branch and open a PR.
    Called by base_agent when Rafael produces code and context has push_to_github=True.
    """
    if not _is_configured():
        return {"status": "skipped", "message": "GITHUB_TOKEN ou GITHUB_REPO não configurados"}

    def _sync():
        from github import Github
        g    = Github(GITHUB_TOKEN)
        repo = g.get_repo(GITHUB_REPO)

        branch_name = f"feat/rafael-{task_id[:8]}"
        base_sha    = repo.get_branch(GITHUB_BASE_BRANCH).commit.sha

        _get_or_create_branch(repo, branch_name, base_sha)
        _commit_file(
            repo,
            file_path=file_path,
            content=lua_code,
            message=f"feat(lua): {task_title}",
            branch=branch_name,
        )

        pr = repo.create_pull(
            title=f"[Rafael] {task_title}",
            body=pr_body or (
                f"Implementação Lua gerada pelo agente Rafael.\n\n"
                f"**Task ID:** `{task_id}`\n"
                f"**Arquivo:** `{file_path}`\n\n"
                f"> _Revisar antes de fazer merge. QA recomendado (Sophia)._"
            ),
            head=branch_name,
            base=GITHUB_BASE_BRANCH,
        )

        return {
            "status":    "success",
            "pr_url":    pr.html_url,
            "branch":    branch_name,
            "pr_number": pr.number,
            "file_path": file_path,
        }

    try:
        return await asyncio.to_thread(_sync)
    except Exception as e:
        print(f"[GITHUB] push_lua_file error: {e}")
        return {"status": "error", "message": str(e)}


async def push_cpp_file(
    file_path: str,
    cpp_code: str,
    task_id: str,
    task_title: str,
    pr_body: str = "",
) -> dict:
    """
    Commit a C++ file or patch to a new branch and open a PR.
    Called by base_agent when Viktor produces code and context has push_to_github=True.
    """
    if not _is_configured():
        return {"status": "skipped", "message": "GITHUB_TOKEN ou GITHUB_REPO não configurados"}

    def _sync():
        from github import Github
        g    = Github(GITHUB_TOKEN)
        repo = g.get_repo(GITHUB_REPO)

        branch_name = f"fix/viktor-{task_id[:8]}"
        base_sha    = repo.get_branch(GITHUB_BASE_BRANCH).commit.sha

        _get_or_create_branch(repo, branch_name, base_sha)

        # If the path looks like a source file, save it there.
        # Otherwise save as a patch under patches/
        target = (
            file_path
            if file_path.endswith((".cpp", ".h", ".c", ".hpp"))
            else f"patches/viktor_{task_id[:8]}.patch"
        )

        _commit_file(
            repo,
            file_path=target,
            content=cpp_code,
            message=f"fix(engine): {task_title}",
            branch=branch_name,
        )

        pr = repo.create_pull(
            title=f"[Viktor] {task_title}",
            body=pr_body or (
                f"Modificação de engine C++ gerada pelo agente Viktor.\n\n"
                f"**Task ID:** `{task_id}`\n"
                f"**Arquivo:** `{target}`\n\n"
                f"> _Requer revisão manual e compilação local antes do merge._"
            ),
            head=branch_name,
            base=GITHUB_BASE_BRANCH,
        )

        return {
            "status":    "success",
            "pr_url":    pr.html_url,
            "branch":    branch_name,
            "pr_number": pr.number,
            "file_path": target,
        }

    try:
        return await asyncio.to_thread(_sync)
    except Exception as e:
        print(f"[GITHUB] push_cpp_file error: {e}")
        return {"status": "error", "message": str(e)}
