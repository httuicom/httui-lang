# Benchmark fixture

### Block 1

```http alias=req1 timeout=30000
GET https://api.example.com/items?page=1
Authorization: Bearer {{TOKEN}}
Content-Type: application/json

{"page": 1}
```


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.
### Block 2

```db-postgres alias=q2
SELECT id, name, created_at FROM items WHERE name = {{req1.response.body.name}}
```


- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
### Block 3

```http alias=req3 timeout=30000
GET https://api.example.com/items?parent={{q2.response.body.parent_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req1.response.body.parent_id}}
Content-Type: application/json

{"page": 1}
```

- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

### Block 4

```db-postgres alias=q4
SELECT id, name, created_at FROM items WHERE owner_id = {{req3.response.body.owner_id}} AND owner_id = {{q2.response.body.owner_id}} AND owner_id = {{req1.response.body.owner_id}}
```

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

### Block 5

```http alias=req5 timeout=30000
GET https://api.example.com/items?parent={{q4.response.body.status}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req3.response.body.status}}
Content-Type: application/json

{"ref": "{{q2.response.body.status}}", "page": 1}
```

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

### Block 6

```db-postgres alias=q6
SELECT id, name, created_at FROM items WHERE id = {{req5.response.body.id}} AND id = {{q4.response.body.id}} AND id = {{req3.response.body.id}} AND id = {{q2.response.body.id}}
```

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.

### Block 7

```http alias=req7 timeout=30000
GET https://api.example.com/items?parent={{q6.response.body.name}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req5.response.body.name}}
Content-Type: application/json

{"ref": "{{q4.response.body.name}}", "page": 1}
```


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.
### Block 8

```db-postgres alias=q8
SELECT id, name, created_at FROM items WHERE parent_id = {{req7.response.body.parent_id}} AND parent_id = {{q6.response.body.parent_id}} AND parent_id = {{req5.response.body.parent_id}} AND parent_id = {{q4.response.body.parent_id}}
```


- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
### Block 9

```http alias=req9 timeout=30000
GET https://api.example.com/items?parent={{q8.response.body.owner_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req7.response.body.owner_id}}
Content-Type: application/json

{"ref": "{{q6.response.body.owner_id}}", "page": 1}
```

- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

### Block 10

```db-postgres alias=q10
SELECT id, name, created_at FROM items WHERE status = {{req9.response.body.status}} AND status = {{q8.response.body.status}} AND status = {{req7.response.body.status}} AND status = {{q6.response.body.status}}
```

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

A longer paragraph that talks through the data flow between blocks and why the reference chain matters for the downstream query.

> A blockquote with a caveat about pagination.


Some explanatory prose about the request below and what it returns.

- a bullet point describing a field
- another bullet describing an edge case

## Section heading

