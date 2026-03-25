from e2b_code_interpreter import Sandbox
import os

E2B_API_KEY = os.getenv("E2B_API_KEY")

async def run_lua_test(lua_code: str, test_description: str) -> dict:
    """
    Run Lua code in E2B sandbox and return results
    Used by Sophia for QA testing
    """
    if not E2B_API_KEY:
        return {"status": "error", "message": "E2B_API_KEY not configured"}

    try:
        # NOTE: Sandbox is used as a context manager for easy cleanup
        with Sandbox(api_key=E2B_API_KEY) as sandbox:
            # Install Lua 5.1 — TFS OTServ uses Lua 5.1 API
            sandbox.commands.run("apt-get update && apt-get install -y lua5.1 2>/dev/null")

            # Write the Lua script
            sandbox.files.write("/tmp/test.lua", lua_code)

            # Run it
            result = sandbox.commands.run("lua5.1 /tmp/test.lua")

            return {
                "status": "success" if result.exit_code == 0 else "failed",
                "exit_code": result.exit_code,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "test_description": test_description
            }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e),
            "test_description": test_description
        }

async def run_python_analysis(python_code: str) -> dict:
    """Run Python analysis code in sandbox"""
    if not E2B_API_KEY:
        return {"status": "error", "message": "E2B_API_KEY not configured"}

    try:
        with Sandbox(api_key=E2B_API_KEY) as sandbox:
            result = sandbox.commands.run(f"python3 -c '{python_code}'")
            return {
                "status": "success" if result.exit_code == 0 else "failed",
                "stdout": result.stdout,
                "stderr": result.stderr
            }
    except Exception as e:
        return {"status": "error", "message": str(e)}
