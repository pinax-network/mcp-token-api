import { Prompt } from "fastmcp";

export const instructions = `These are instructions on how to use the tools from the Token API MCP.
The MCP provides access to a collection of databases for multiple blockchain networks.
The naming convention for the databases is as follows:
    {network}:{database_name}@{version}
Versions are incremental and latest versions have the latest features in terms of tables implemented.
The one version prior to the latest version is kept as a backup and for compatibility until it is replaced by the current version once a newer version comes out.

The databases are currently segregated into three main themes:
    - Tokens: tables for ERC20 balances, holders, historical data, transfers, etc.
    - NFT: tables for ERC721 and ERC1155 standards as well as other NFT types, transfers, Seaport marketplace prices, holders, wallet, etc.
    - Uniswap: tables for ERC20 token prices, swaps, market data, etc.
You can assume that the databases contain the whole blockchain history.

In order to discover the data, the MCP provides 4 main tools:
    1. 'list_databases': use this to discover which networks and databases are available.
    2. 'list_tables': use this to discover which tables are available for a specific database.
    3. 'describe_table': use this to get the schema of a particular table inside a database with fields and columns types.
    4. 'run_query': run a read-only SQL query using the ClickHouse query syntax.

Thus, the process of answering a users question should generally follow the steps in order presented above, first discovering networks and databases, then listing tables and finding out which one are relevant, getting the schema of those table to accurately construct and run a SQL query.
A few important tips on making queries:
    - Make sure to always get the schema of table first and not guess at column names.
    - Prefer adding LIMIT clauses to queries first to only get a sample of the data and to validate that the query is correct and relevant in the user's context. Then you can retrieve the full data if needed.
    - Be wary of resource consumption for queries, avoid too much JOIN and aggregation operations unless necessary.
    - Always use backticks when adding the database name in the query (e.g. SELECT * FROM \`database\`.table ...)
    - Remember that token names and symbols are *not* identifiable information, only the addresses are. A legitimate token can be impersonated by using the same name and symbol but its address would determine the truthworthiness. Don't rely on just name and symbols for Token queries.
    - ClickHouse may present duplicate data in the answer or multiple rows for the same unique field. That is because of the MergeTree engine functionning. You can use the 'FINAL' instruction to avoid that *but* be wary of its resource cost. Queries may take a lot longer using this keyword.
    - Avoid using functions on column names in filters as ClickHouse would not be able to take advantage of the pre-computed indexes like bloom-filters, projections and primary keys. You should aim to always use filters that are part of a index, either as primary or secondary. You can use 'SHOW CREATE TABLE' statements to identify the indexes for a given table.
`;

export default [
    {
        name: "mcp_token_api_general_instructions",
        description: "General instructions for language models on how to make the best use of the tools and resources provided by the Token API MCP.",
        load: async () => {
            return instructions;
        }
    },
] as Prompt[];