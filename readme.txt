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
