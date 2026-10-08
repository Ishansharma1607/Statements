Review the exception handling in "prc_mlv_customer_addl_info".

Mohan requested "p_success_flag" and "p_error_message" OUT parameters so Java can read the result.

Currently, the exception block assigns the OUT parameters but also calls "RAISE_APPLICATION_ERROR(-20001, ...)" and performs "ROLLBACK".

Please verify whether this is consistent with the existing incoming static-message procedures and Java integration conventions.

Specifically:

1. Check whether raising an exception prevents Java from receiving the OUT parameters.
2. Check whether the wrapper should perform "ROLLBACK", considering caller-managed transactions.
3. Verify that success and error results from the delegated procedure are correctly propagated.
4. Review handling of "NO_DATA_FOUND" from the branch-description lookup.
5. Recommend the safest implementation consistent with existing project patterns.

Do not modify code yet. Explain any issues and recommended changes first.


----------
Task: Implement Mohan's review comments — Jira 42566

I have already implemented "prc_mlv_customer_addl_info" inside:

"Packages/PKG_QLM_INCOMING_STATIC_MSG.sql"

The procedure currently delegates to:

"PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info"

The original implementation has already compiled successfully in the Oracle Dev database, and the previous verification confirmed that all 277 IN parameters matched the existing procedure.

However, Mohan has now reviewed the implementation and requested additional changes.

Please implement all the changes below while preserving existing functionality.

1. Add change history

Follow the existing change-history format in "PKG_QLM_INCOMING_STATIC_MSG.sql".

Add an entry containing:

- Developer: Ishan Sharma
- Jira: 42566
- Date: 08-Oct-2026
- Description: Added customer additional-info incoming static message wrapper with customer existence validation.

Follow the existing history column layout, tab alignment, and comment style.

2. Replace staging table datatype references with main table references

Currently, many procedure parameters use declarations such as:

"qlm_customer_addl_info_q.fo_short_name%TYPE"

Mohan specifically instructed us to use the main table instead of the "_q" staging table for datatype references.

Change these to:

"qlm_customer_addl_info.fo_short_name%TYPE"

Apply this consistently to the new wrapper declaration in both the package specification and package body.

Important:

- Change only the applicable datatype references in the new procedure.
- Verify that every referenced column exists in the main table.
- Do not change actual DML table references.
- Do not modify unrelated procedures.
- Preserve the original parameter names, modes, and defaults.
- Do not blindly replace "_q" references used for other purposes.

3. Add two OUT parameters

Mohan confirmed that Java will need to receive the processing status and error message.

Add the following OUT parameters to the wrapper:

- "p_success_flag OUT VARCHAR2"
- "p_error_message OUT VARCHAR2"

Before adding them, inspect existing package conventions and confirm the appropriate datatype declarations.

Update both package specification and body consistently.

Preserve all existing 277 IN parameters.

The new wrapper should expose 277 IN parameters plus 2 OUT parameters, provided no other existing signature changes are required.

4. Add customer existence and active-status validation

Before invoking:

"PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info"

validate that the customer exists in "qlm_customer" for the supplied customer code and branch code, and is active.

Mohan provided this exact reference logic:

SELECT COUNT(1)
INTO lv_customer_maintenance
FROM qlm_customer
WHERE branch_code = p_branch_code
AND customer_code = p_customer_code
AND active_flag = 1;

IF lv_customer_maintenance = 0 THEN
    p_success_flag := 'N';
    p_error_message := lv_branch_desc || '/' || p_customer_code ||
                       ' Customer is not maintained for the branch';
    RETURN;
END IF;

Implement this logic in the wrapper.

Requirements:

- Declare "lv_customer_maintenance" with an appropriate datatype.
- Confirm that "p_branch_code" and "p_customer_code" exist in the wrapper and use the correct values.
- Confirm the actual "qlm_customer" table columns.
- Use "active_flag = 1", as Mohan instructed.
- Run this validation before invoking the existing edit procedure.
- If no matching active customer exists, set the success flag to "N", populate the error message, and return immediately.
- If the customer exists, continue to the existing procedure.

The reference uses "lv_branch_desc". Check whether this variable is available in the wrapper. If not, find the existing project pattern for obtaining the branch description. Do not invent its value.

If branch-description lookup is unnecessary or unavailable, explain the safest approach before making assumptions.

5. Handle success and error output correctly

The new OUT parameters must return meaningful results to the Java caller.

Inspect the existing procedure's OUT parameters and determine how the existing processing success flag and error message are returned.

Ensure:

- Customer-validation failure returns "N" and the appropriate message.
- Successful delegated processing returns the appropriate success status.
- Delegated processing failures are not incorrectly reported as success.
- Existing business errors are preserved where possible.
- No business validation or CRUD logic is duplicated unnecessarily.

Do not simply set "p_success_flag := 'Y'" after calling the existing procedure without checking its actual result.

Follow existing project conventions for exception handling.

6. Follow Mohan's formatting conventions

Mohan explicitly requested:

- SQL and PL/SQL keywords in uppercase ("SELECT", "FROM", "WHERE", "IF", "THEN", "END IF", "RETURN", etc.).
- Table names and column names in lowercase.
- Tab-based indentation and alignment.
- Consistent parameter alignment.
- Properly aligned "IF" and "END IF" blocks.
- Consistent formatting with nearby existing procedures.

Apply these conventions to the newly added or modified code.

Avoid unrelated formatting changes throughout the large package.

7. Preserve existing implementation

Do not:

- Remove any required IN parameters.
- Change the existing procedure's business logic.
- Modify "PKG_CUSTOMER_ADDL_INFO_MGMT".
- Change unrelated procedures.
- Add unnecessary database operations.
- Modify unrelated files.
- Commit, push, or deploy changes automatically.

8. Perform verification

After implementing the changes:

1. Compare the wrapper's 277 IN parameters with the existing "prc_edit_customer_addl_info" IN parameters.
2. Verify parameter names, modes, types, and defaults, accounting for the intentional switch from "_q" to the main table.
3. Verify both new OUT parameters.
4. Verify package specification and body signatures match.
5. Verify that the customer check occurs before the delegate call.
6. Verify that missing or inactive customers cannot reach the delegate call.
7. Verify success and error output handling.
8. Verify the existing delegate parameter mappings remain correct.
9. Review the Git diff for unrelated changes.

If authorized database access is available, use read-only metadata queries to verify table columns and parameter declarations.

Do not execute data-changing procedures or compile/deploy changes automatically.

Final report

Provide:

- Files modified
- Change-history update
- Main-table datatype references updated
- Customer validation added
- OUT parameters added
- Success/error propagation behavior
- Parameter verification results
- Formatting verification
- Any unresolved questions
- Exact database compilation and validation steps for me to perform manually

Important: Do not silently invent business rules or substitute guessed values. If a required detail cannot be established from existing code or Mohan's sample, identify the uncertainty and ask me before proceeding.


---------


Based on the Jira/task requirements and the repository code, help me understand the business/integration context of Jira 42566.

Specifically find:
1. What exact customer additional/static data this change handles.
2. Which upstream system/service sends this data to QFXLM.
3. What QFX/QFXLM represents in this flow.
4. How the data reaches PKG_QLM_INCOMING_STATIC_MSG.
5. What happens after prc_mlv_customer_addl_info receives it.

Search the repository for evidence. Do not guess. Clearly mark anything that cannot be determined from the code and needs confirmation from Mohan.

Give me a short 30-second explanation I can say to my lead.

-----


Ignore problem-report.html and all Gradle wrapper related changes.
Those are intentional manual changes and are unrelated to this task.

Now perform a second independent verification focused ONLY on the
PL/SQL implementation.

Do not rely on your previous review conclusion and do not modify code.

Compare the CURRENT declaration of:

PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

against:

PKG_QLM_INCOMING_STATIC_MSG.prc_mlv_customer_addl_info

Verify mechanically:

1. Every current IN parameter of prc_edit_customer_addl_info exists
   in prc_mlv_customer_addl_info.
2. There are no missing IN parameters.
3. There are no unexpected extra IN parameters.
4. Parameter names match exactly.
5. Datatypes, %TYPE references and collection types match.
6. Default values are preserved where applicable.
7. The package specification and package body signatures match.
8. Every wrapper IN parameter is mapped to the correct corresponding
   parameter when prc_edit_customer_addl_info is invoked.
9. No parameter is accidentally mapped to a similarly named but
   different parameter.
10. No delegate parameter is mapped twice or omitted.

The existing OUT parameters/cursors may be handled using local variables
inside the wrapper; do not require them to be exposed in the new
procedure's public signature.

Give me exact counts and a concise result:

SOURCE IN PARAMETER COUNT:
WRAPPER IN PARAMETER COUNT:
MATCHED:
MISSING:
EXTRA:
TYPE/DEFAULT MISMATCHES:
DELEGATE MAPPING ISSUES:
SPEC/BODY MISMATCHES:

FINAL RESULT: PASS or ISSUES FOUND

For every issue found, provide the exact parameter name and source/wrapper
file locations.

---



Context / requirement:

I was asked to add a new wrapper procedure:
PKG_QLM_INCOMING_STATIC_MSG.prc_mlv_customer_addl_info

The wrapper is for incoming customer additional-information updates.

The existing procedure containing the actual business logic is:
PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

The new wrapper should:
- contain all current IN parameters of prc_edit_customer_addl_info
- delegate to the existing prc_edit_customer_addl_info
- reuse the existing business logic
- not duplicate CRUD/validation/business logic
- not modify PKG_CUSTOMER_ADDL_INFO_MGMT
- be declared and implemented inside the existing
  PKG_QLM_INCOMING_STATIC_MSG package
- not create a new package or standalone procedure

The requirement owner specifically clarified that the new procedure
should keep all IN parameters from the existing
prc_edit_customer_addl_info.

The implementation has already been completed and successfully compiled
in the Dev Oracle database with no errors.

Your task now is REVIEW ONLY. Do not modify code unless I explicitly
ask you after the review.



The implementation of `prc_mlv_customer_addl_info` in
`Packages/PKG_QLM_INCOMING_STATIC_MSG.sql` is now complete.

Do NOT modify any code yet.

I want you to perform a thorough review of my current uncommitted changes before I submit them for review.

Please do the following:

1. Inspect the current Git diff and identify exactly what I changed.

2. Review the current declaration of:
   `PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info`
   Treat the CURRENT repository version as the source of truth.

3. Verify the new:
   `PKG_QLM_INCOMING_STATIC_MSG.prc_mlv_customer_addl_info`

   against that existing procedure.

4. Specifically verify:
   - Every required IN parameter from `prc_edit_customer_addl_info`
     is present in `prc_mlv_customer_addl_info`.
   - Parameter names are correct.
   - Datatypes and `%TYPE` references are correct.
   - Collection/record parameter types are correct.
   - Parameter defaults are preserved where applicable.
   - There are no obsolete or extra parameters accidentally copied.
   - The package specification and package body declarations match.
   - The wrapper passes the parameters to
     `PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info`
     correctly.
   - Prefer named parameter notation in the delegate call and verify
     that every mapping goes to the correct parameter.
   - No required IN parameter is omitted.
   - No business logic, DML, validation or transformation was
     unnecessarily duplicated in the wrapper.
   - `PKG_CUSTOMER_ADDL_INFO_MGMT.sql` itself has not been modified.

5. Search the repository for the sample/reference wrapper mentioned for
   this flow and compare its delegation pattern with my implementation.
   Also inspect similar wrappers in `PKG_QLM_INCOMING_STATIC_MSG`.

6. Check the Git diff for accidental formatting changes, unrelated
   modifications, duplicate procedure declarations, or other files
   changed unintentionally.

7. Do NOT edit anything automatically.

At the end give me a review report in this format:

VERDICT:
PASS / ISSUES FOUND

GIT CHANGES:
- files changed
- intended vs suspicious changes

SPEC/BODY:
- whether signatures match

PARAMETER VERIFICATION:
- expected IN parameter count
- wrapper IN parameter count
- missing parameters
- extra parameters
- datatype/default mismatches

DELEGATE CALL:
- missing mappings
- incorrect mappings
- suspicious mappings

REFERENCE IMPLEMENTATION:
- what was compared
- relevant differences

RISKS / ISSUES:
- exact file and line for every issue

DATABASE VALIDATION STILL REQUIRED:
- SQL statements I should run manually in Oracle SQL Developer

Do not claim that Oracle compilation or runtime behavior is verified
unless it can actually be established from the repository.


_—-----
Now perform a second independent review focused only on parameter mapping.
Do not rely on your previous conclusion.

Programmatically compare the current IN parameters of
PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info against
prc_mlv_customer_addl_info and its delegate call.

Report any missing, extra, duplicated, reordered, incorrectly typed,
or incorrectly mapped parameter. Do not modify code.

--------
Clarification received: For the new prc_mlv_customer_addl_info procedure, include all IN parameters from the existing PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info.
Use the current declaration in the repository as the source of truth for parameter names, order, datatypes, %TYPE references, collection types, and default values.
The requirement is specifically all IN parameters. Do not expose the existing OUT parameters or OUT cursors as parameters of the new wrapper unless they are required internally for calling the existing procedure.
Please re-analyze the implementation using this clarification and proceed.


Hi Mohan, one small clarification for prc_mlv_customer_addl_info. For the new procedure, should I keep all the IN parameters from the existing prc_edit_customer_addl_info, or only the parameters required for the MLV flow?


IMPLEMENTATION TASK — QFXLM CUSTOMER ADDITIONAL INFO MLV WRAPPER

OBJECTIVE

Add a new incoming-flow wrapper procedure for Customer Additional Information in the existing QFXLM database package.

The upstream/MLV flow will eventually supply customer additional-information data to QFXLM.

For this task, DO NOT implement the upstream integration itself.

The new procedure must delegate to the existing customer additional-information procedure so that the existing validation, CRUD behavior, authorization, queue handling, error handling, and other existing business logic continue to remain centralized in the existing implementation.


============================================================
1. FILE TO MODIFY
============================================================

Modify ONLY:

Packages/PKG_QLM_INCOMING_STATIC_MSG.sql

Do NOT create:

- a new package
- a standalone procedure file
- a new table
- a new directory
- a new Java service
- an API
- integration code
- migration scripts unless the repository's established structure absolutely requires one for this package change


============================================================
2. NEW PROCEDURE
============================================================

Add the following public procedure to the existing package:

prc_mlv_customer_addl_info

The procedure must be added according to the existing structure of:

PKG_QLM_INCOMING_STATIC_MSG

If this SQL file contains both the package specification and package body, add:

1. The procedure declaration to the PACKAGE SPECIFICATION.
2. The procedure implementation to the PACKAGE BODY.

Follow the formatting, naming, indentation, comments, exception handling, parameter declaration style, and other conventions already used in this package.


============================================================
3. EXISTING PROCEDURE TO DELEGATE TO
============================================================

The new procedure must reuse the existing procedure:

PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

The source of truth for the existing procedure's CURRENT signature is:

Packages/PKG_CUSTOMER_ADDL_INFO_MGMT.sql

DO NOT modify PKG_CUSTOMER_ADDL_INFO_MGMT.sql.

DO NOT duplicate the implementation of prc_edit_customer_addl_info.

The new procedure is intended to be a thin wrapper/delegation layer.


============================================================
4. IMPORTANT — ANALYZE BEFORE IMPLEMENTING
============================================================

Before making any code change, inspect the repository.

First inspect:

Packages/PKG_CUSTOMER_ADDL_INFO_MGMT.sql

Locate the CURRENT declaration and implementation of:

prc_edit_customer_addl_info

Understand its:

- current parameter names
- parameter order
- IN / OUT / IN OUT directions
- parameter data types
- %TYPE references
- collection types
- default values
- cursor parameters
- error/result parameters
- relevant exception behavior

Do NOT rely on an old test, old branch, comments, documentation, or another outdated copy of the procedure signature.

The current production repository declaration is authoritative.


============================================================
5. FIND EXISTING CALLERS
============================================================

Search the entire repository for:

prc_edit_customer_addl_info

Inspect existing call sites to understand the expected invocation style.

In particular, look for wrappers/adapters that invoke this procedure from another incoming/static flow.

Use those implementations as references for:

- parameter mapping
- named-parameter notation
- handling of control parameters
- OUT parameters
- cursor parameters
- exception handling
- logging
- comments
- transaction handling

Do NOT blindly copy an older wrapper if its signature differs from the current procedure.


============================================================
6. IMPORTANT REFERENCE WRAPPERS
============================================================

Inspect relevant existing wrapper implementations in the repository.

One known example to inspect is:

PKG_QLM_INCOMING_STATIC_MSG.prc_static_cust_acc_update

Also inspect any existing wrapper/caller around:

PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

Use the closest CURRENT implementation as the primary pattern.

The reference implementation should guide structure and conventions, but the CURRENT declaration of prc_edit_customer_addl_info remains the source of truth for its callable contract.


============================================================
7. PARAMETER CONTRACT — DO NOT GUESS
============================================================

The requirement communicated for the new procedure is that it should receive the required customer additional-information IN parameters and delegate to the existing procedure.

However, DO NOT automatically assume that the new wrapper must expose every OUT / IN OUT / SYS_REFCURSOR parameter of prc_edit_customer_addl_info.

Determine the intended wrapper contract using, in this order:

1. Jira/task description, if available in the current context.
2. The supplied/reference wrapper implementation.
3. Existing equivalent MLV/incoming wrappers in this repository.
4. Existing package conventions.

If these sources clearly establish the wrapper signature, implement that signature.

If they do NOT establish whether OUT / IN OUT / cursor parameters should be exposed by prc_mlv_customer_addl_info, DO NOT invent a contract.

STOP before implementation and explicitly report the ambiguity.

Tell me:

- which parameters are ambiguous
- what the existing procedure exposes
- what the closest wrapper exposes
- what decision is required

I will confirm before implementation continues.


============================================================
8. INPUT PARAMETERS
============================================================

The new wrapper should expose the customer additional-information INPUT parameters required by the MLV flow.

For parameters that are passed through to:

PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

preserve the CURRENT:

- parameter name where appropriate
- datatype
- %TYPE reference
- collection type
- semantics
- default value where required by the wrapper contract

Do not silently omit required customer data.

Do not transform values unless the Jira/reference implementation explicitly requires a transformation.


============================================================
9. DEFAULT VALUES
============================================================

Do NOT accidentally remove existing/default semantics when constructing the wrapper.

Inspect the CURRENT procedure and relevant reference wrappers for defaults.

Examples previously observed in repository analysis may include defaults such as:

p_copied_from_pri_branch_flag DEFAULT 0
p_copy_to_sub_branch_flag DEFAULT 0
p_mxn_statement_setup DEFAULT 0

These names/examples MUST be verified against the current repository before use.

Do not add them merely because they are listed here.

The current source code is authoritative.


============================================================
10. OBSOLETE PARAMETERS
============================================================

Do not introduce obsolete parameter names from older implementations.

Repository history may contain old signatures.

For example, if current code uses a newer parameter and an older wrapper uses an obsolete equivalent, use the CURRENT contract.

Previously observed examples that MUST be verified before relying on them include:

current:
p_spot_waive_inc_conf_flag

possibly obsolete:
p_waive_incoming_conf_flag

Do not add old/removed parameters simply to make an outdated example compile.


============================================================
11. CONTROL PARAMETERS
============================================================

Pay special attention to control parameters such as:

p_user_id
p_auto_auth_flag
p_action

and any equivalent parameters found in the CURRENT procedure.

Do NOT invent hard-coded values such as:

'SYSTEM'
'ISGDATA'
'C'
'E'

unless an authoritative existing MLV/reference wrapper or the Jira explicitly requires those values.

If it is unclear whether a control parameter should:

- be supplied by the caller,
- be exposed by the wrapper,
- be derived,
- or be fixed internally,

STOP and report the ambiguity rather than guessing.


============================================================
12. DELEGATION IMPLEMENTATION
============================================================

The body of:

prc_mlv_customer_addl_info

should be a thin delegation layer.

Conceptually:

PROCEDURE prc_mlv_customer_addl_info (...) IS
BEGIN

    PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info(
        p_xxx => p_xxx,
        p_yyy => p_yyy,
        ...
    );

END prc_mlv_customer_addl_info;

This is ONLY conceptual pseudocode.

Generate the actual implementation from the CURRENT repository definitions.

Prefer NAMED PARAMETER NOTATION for the delegate call:

parameter_name => local_parameter

This is especially important because the delegated procedure has a large signature and may change over time.


============================================================
13. DO NOT DUPLICATE BUSINESS LOGIC
============================================================

prc_mlv_customer_addl_info must NOT independently implement logic already handled by:

PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

Therefore, unless an existing authoritative wrapper explicitly requires otherwise, do NOT add:

- direct INSERT statements
- direct UPDATE statements
- direct DELETE statements
- duplicate validation
- duplicate authorization logic
- duplicate customer CRUD logic
- duplicate queue handling
- duplicate error handling
- duplicate customer-data transformation


============================================================
14. TRANSACTION HANDLING
============================================================

Do NOT introduce:

COMMIT
ROLLBACK
SAVEPOINT

or new transaction behavior merely for this wrapper.

Follow the existing package convention.

If the existing wrapper pattern contains transaction behavior, explain why it applies before copying it.


============================================================
15. EXCEPTION HANDLING
============================================================

Follow the existing convention in:

PKG_QLM_INCOMING_STATIC_MSG

and the closest equivalent wrapper.

Do NOT add generic:

WHEN OTHERS THEN ...

logic merely because it seems safer.

Do not swallow exceptions.

Do not replace the existing procedure's error behavior with a new behavior.

The wrapper should preserve existing semantics unless the requirement explicitly says otherwise.


============================================================
16. OUT / CURSOR VALUES
============================================================

If repository/Jira/reference analysis confirms that the new wrapper must expose OUT or IN OUT parameters, ensure they are correctly passed through and returned to the wrapper caller.

If cursor parameters are part of the confirmed wrapper contract, preserve their correct Oracle types and behavior.

Do not create new cursor semantics.

Again: if whether these outputs should be publicly exposed is ambiguous, STOP and ask rather than guessing.


============================================================
17. OUT OF SCOPE
============================================================

Do NOT perform the following as part of this change:

- Modify PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info.
- Modify existing customer tables.
- Create new tables.
- Create new packages.
- Add database migration logic unrelated to exposing this procedure.
- Implement upstream MLV integration.
- Implement API/application changes.
- Implement Java/Spring Boot changes.
- Implement messaging/consumer logic.
- Implement end-to-end partner-message testing.
- Replace the existing customer CRUD implementation.
- Refactor unrelated legacy code.
- Clean up unrelated code while touching the package.

Keep the diff minimal and directly related to this requirement.


============================================================
18. VALIDATION REQUIRED FOR THIS TASK
============================================================

The primary validation requested by the team is Oracle compilation in the DEV database.

After implementation, the modified package should compile successfully in DEV.

At minimum verify:

PKG_QLM_INCOMING_STATIC_MSG package specification = VALID
PKG_QLM_INCOMING_STATIC_MSG package body = VALID

and there are no compilation errors caused by the change.

Use the repository/team's normal deployment/compilation process.

Do not execute against production.


============================================================
19. DEPENDENCY VALIDATION
============================================================

Because the new procedure delegates to:

PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

verify that the current dependency signature matches the delegate invocation.

Do NOT modify/recompile unrelated code merely for completeness.

If normal DEV installation requires compiling the dependency first, follow the repository's established process.

Otherwise avoid unnecessary changes.


============================================================
20. SOURCE-LEVEL VALIDATION
============================================================

Before considering implementation complete, verify:

- prc_mlv_customer_addl_info is declared in the correct package specification.
- prc_mlv_customer_addl_info is implemented in the corresponding package body.
- Specification and body signatures match exactly.
- Parameter directions are correct.
- Parameter types are correct.
- Required defaults are preserved where applicable.
- Required collection types are correct.
- Required %TYPE references are correct.
- No obsolete parameter names were introduced.
- Delegate call uses named notation where practical.
- Every required delegated input is mapped correctly.
- No parameter is accidentally mapped to the wrong parameter.
- The delegate is invoked exactly once for the normal flow.
- No direct customer table DML was introduced.
- PKG_CUSTOMER_ADDL_INFO_MGMT.sql remains unchanged.
- No unrelated files were modified.


============================================================
21. TESTING SCOPE
============================================================

Do NOT invent an end-to-end test for the upstream integration.

The team has stated that the integration/end-to-end flow will be handled separately/later.

For this change, successful DEV Oracle package compilation is the primary required validation.

If there is an existing safe repository/unit validation that naturally applies to package compilation, it may be run.

Do not use production data.

Do not fabricate customer data or execute potentially mutating stored-procedure calls merely to prove the wrapper works.


============================================================
22. BUILD VALIDATION
============================================================

If this repository has a normal lightweight build/static validation that applies to database packages, inspect it and run it if appropriate.

Do NOT treat a Gradle/build success as proof that Oracle PL/SQL compiles unless that build actually performs Oracle compilation.

Oracle DEV compilation remains the authoritative validation for the PL/SQL change.


============================================================
23. BEFORE WRITING CODE — REPORT YOUR ANALYSIS
============================================================

IMPORTANT:

Do NOT immediately edit the file.

First analyze the repository and respond with:

A. Exact location of the current
   PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info
   declaration.

B. Exact location of its implementation.

C. Current parameter count grouped by:
   - IN
   - OUT
   - IN OUT

D. Relevant collection/cursor parameters.

E. Existing callers/wrappers found.

F. The closest wrapper implementation that should be used as the pattern.

G. Whether the repository/Jira/reference code clearly establishes the contract for:
   prc_mlv_customer_addl_info

H. Specifically state whether the new wrapper should expose:
   - only IN parameters
   - IN + OUT parameters
   - IN + OUT + IN OUT/cursors

I. Any ambiguity that requires developer confirmation.

J. Exact file(s) you intend to modify.

K. Short implementation plan.

DO NOT MODIFY CODE YET.

Wait for my confirmation after presenting this analysis.


============================================================
24. AFTER I APPROVE THE ANALYSIS
============================================================

Only after I explicitly approve your analysis:

1. Modify Packages/PKG_QLM_INCOMING_STATIC_MSG.sql.
2. Add the public procedure declaration.
3. Add its body implementation.
4. Delegate to the existing procedure.
5. Keep the diff minimal.
6. Do not modify unrelated code.
7. Show me the resulting diff.
8. Explain any parameter that is not a direct pass-through.
9. Provide the exact DEV compilation/validation steps appropriate for this repository.
10. Do NOT commit or push unless I explicitly ask you to.


============================================================
ACCEPTANCE CRITERIA
============================================================

The task is complete when:

1. PKG_QLM_INCOMING_STATIC_MSG.prc_mlv_customer_addl_info exists in the appropriate package specification and body.

2. Its signature matches the confirmed MLV wrapper contract.

3. It delegates customer additional-information processing to:

   PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info

4. The existing customer additional-information implementation remains unchanged.

5. Required parameters are mapped accurately.

6. No obsolete parameters are introduced.

7. No unconfirmed constants or mappings are invented.

8. No customer CRUD/business logic is duplicated.

9. No unrelated files/code are modified.

10. The modified package specification and body compile successfully in the DEV Oracle database.

11. There are no Oracle compilation errors caused by the change.

12. No end-to-end upstream integration work is included in this task.


============================================================
FINAL SAFETY RULE
============================================================

When repository evidence is insufficient, DO NOT GUESS.

This is a legacy financial application and the existing procedure has a large interface.

It is preferable to stop and ask one precise question than to silently invent a parameter mapping, constant, OUT contract, transaction behavior, or business rule.





Hello. Yeah, hi. Yeah. Okay. Let me share my screen. So did you check out the database repository? We have a separate repository for database stored procedures, functions, everything. I imported the JSON in SQL Developer. That's it. It was just one, I think one database for dev. Okay. Okay. So basically we have a separate repository for these SQL related things, for all the tables, whatever we are using in our application, right? The table structure, stored procedures, functions, everything. So everything, all the code changes, you may check out that code as well. There is a small change in that. I will explain the process so that you can go through that once, okay? So basically we have a static screen, okay? So customer related static screen is there. So this is the particular table structure, okay? This is the table structure for that customer related information gets stored here. Okay? This is the table, customer additional info, they call it as. For this we have one screen, edit screen is there. I mean they can create a customer, these details, and they can edit it. It's a normal static screen: save, update, edit, right? For that we have a separate dedicated screen, okay? So whenever they do some modification, right, edit, any some details, we will invoke a stored procedure. This customer additional info management is a package. This is the package. So basically instead of directly invoking the table, here they have a stored procedure. This procedure will have a edit, I mean fetch the record they are having, get details, get procedure. To search they have a search, and if edit they have an edit customer additional. So instead of invoking direct table, they are maintaining one stored procedure and inside that they have all CRUD operations. So this edit customer info, this procedure will have all the in params. So whatever fields, right, all these are fields. So from the screen it will pass this information, and it will get updated in the particular table. Okay? So now instead of screen, right, we will get this information from another system, from another partner, upstream partner. They will create, consider that is the golden source for these customers. So once all the customers are maintained there, that will be flown into our system, and we need to capture that in this table. Okay? So whenever there is a flow from another system, right? So we have to create one more similar procedure, similar kind of procedure. We need to have all the in params, and from that procedure, right, you need to invoke this existing edit customer additional info SP. This procedure we have to invoke from that new one. It's like a wrapper. We are going to create one wrapper. Inside again we are going to invoke this existing our customer edit customer additional info stored procedure. So only this procedure change now we are going to do, this print. So that next print, that consuming flow we are going to take care. So as part of this change, right, just you need to create a new procedure with a different name. Inside you need to consume all the in params are same, same value, same parameters comes from there also. So internally we have to invoke this existing edit customer additional info, this procedure. So that will take care of all the existing, how to insert, everything that will be taken care. So we are going to create one wrapper and invoking the same existing flow, how it is flown, how it is there in the API Excel. Similar. Okay, so just new wrapper to call this procedure. New procedure to call this old procedure. Ah, old procedure. Okay. That new procedure has to write in... This is the existing one. I am just pinging you the details. This is the package existing.
Create in package only you have to create one new procedure with all the in params, similar kind of in params. This is the package. Okay. Maybe we can have...
Declaration is similar to this one. So this one has in params, right? Same way that new one also should have all the in params. Okay. Inside that you need to invoke this edit customer additional info. Okay. Yes. Yeah, just you. Can you ping the repository? Repository. You can. Yeah, this repository. Check out the code, and this edit, right? It's been called in multiple places also. If you want you can refer that as well. Similarly another flow also they have created one wrapper. Inside the wrapper they are invoking this edit SP. That sample also I will ping you. For reference you can, if you want you can refer that as well. Okay. After that this new, how can I test? Should I run it in test? No, no. This one just you need to make sure there is no compilation issue, this procedure, right? Once you commit the change, you need to compile this in Dev, that SP I have given. You know compilation, you know, right? Yes, yes. you have worked on this. Just you need to compile it in the Dev database. Just we need to make sure there is no issue on the procedure. That is enough as of now, because that integration, right, that next part we are going to take care, integrating this end-to-end testing. This folder structure where I have to create, like this, I am seeing very too many folders here. Already there is a SP, right, this procedure, this one, this incoming, right? Inside the package only you are going to write. Okay, no need to create new anything. New package? No need to create a new package. Okay. So this package alone. Where it is? Can you paste the path? Here you need to declare procedure and... Okay. I will check and I will check in the code and I will see. Yeah, just start analysis. Yeah, just check that code. So you can, any doubts let me know, we will connect it. Yeah, sure. I will create on Jira for this and I will share you that. You can create a branch from that Jira. Okay, okay, yeah, sure. Thanks.

sk-51IZjhEhe4CzaN6538D9169d366b423cA1182bB958A5681
aihubmix.com
base_url="https://aihubmix.com/v1",


response = client.chat.completions.create(
    model="ox-alpha",
	
	 model="gemini-3.8-flash-free",
	 
	   model="coding-glm-5.3-free",

sk-apxfe8ba02241b2b8137dc5c9b45f57e700b9042db6e25918
https://api.apinex.bond/v1

free/gemini-3.8-flash
free/muse-spark-1.3
free/glm-5.3-flash
free/deepseek-v4-pro-0813
free/qwen-3.8-max

sk-nry-DV-pXc_TjMnY9eZH7K6I390QX_sy3H4x02rgIW84_m
https://router.bynara.id/v1
qwen3.8-27b
