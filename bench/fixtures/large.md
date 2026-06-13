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

### Block 2

```db-postgres alias=q2
SELECT id, name, created_at FROM items WHERE name = {{req1.response.body.name}}
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

### Block 3

```http alias=req3 timeout=30000
GET https://api.example.com/items?parent={{q2.response.body.parent_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req1.response.body.parent_id}}
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

### Block 4

```db-postgres alias=q4
SELECT id, name, created_at FROM items WHERE owner_id = {{req3.response.body.owner_id}} AND owner_id = {{q2.response.body.owner_id}} AND owner_id = {{req1.response.body.owner_id}}
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

### Block 5

```http alias=req5 timeout=30000
GET https://api.example.com/items?parent={{q4.response.body.status}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req3.response.body.status}}
Content-Type: application/json

{"ref": "{{q2.response.body.status}}", "page": 1}
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

### Block 6

```db-postgres alias=q6
SELECT id, name, created_at FROM items WHERE id = {{req5.response.body.id}} AND id = {{q4.response.body.id}} AND id = {{req3.response.body.id}} AND id = {{q2.response.body.id}}
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

### Block 8

```db-postgres alias=q8
SELECT id, name, created_at FROM items WHERE parent_id = {{req7.response.body.parent_id}} AND parent_id = {{q6.response.body.parent_id}} AND parent_id = {{req5.response.body.parent_id}} AND parent_id = {{q4.response.body.parent_id}}
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

### Block 9

```http alias=req9 timeout=30000
GET https://api.example.com/items?parent={{q8.response.body.owner_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req7.response.body.owner_id}}
Content-Type: application/json

{"ref": "{{q6.response.body.owner_id}}", "page": 1}
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

### Block 10

```db-postgres alias=q10
SELECT id, name, created_at FROM items WHERE status = {{req9.response.body.status}} AND status = {{q8.response.body.status}} AND status = {{req7.response.body.status}} AND status = {{q6.response.body.status}}
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

### Block 11

```http alias=req11 timeout=30000
GET https://api.example.com/items?parent={{q10.response.body.id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req9.response.body.id}}
Content-Type: application/json

{"ref": "{{q8.response.body.id}}", "page": 1}
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

### Block 12

```db-postgres alias=q12
SELECT id, name, created_at FROM items WHERE name = {{req11.response.body.name}} AND name = {{q10.response.body.name}} AND name = {{req9.response.body.name}} AND name = {{q8.response.body.name}}
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

### Block 13

```http alias=req13 timeout=30000
GET https://api.example.com/items?parent={{q12.response.body.parent_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req11.response.body.parent_id}}
Content-Type: application/json

{"ref": "{{q10.response.body.parent_id}}", "page": 1}
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

### Block 14

```db-postgres alias=q14
SELECT id, name, created_at FROM items WHERE owner_id = {{req13.response.body.owner_id}} AND owner_id = {{q12.response.body.owner_id}} AND owner_id = {{req11.response.body.owner_id}} AND owner_id = {{q10.response.body.owner_id}}
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

### Block 15

```http alias=req15 timeout=30000
GET https://api.example.com/items?parent={{q14.response.body.status}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req13.response.body.status}}
Content-Type: application/json

{"ref": "{{q12.response.body.status}}", "page": 1}
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

### Block 16

```db-postgres alias=q16
SELECT id, name, created_at FROM items WHERE id = {{req15.response.body.id}} AND id = {{q14.response.body.id}} AND id = {{req13.response.body.id}} AND id = {{q12.response.body.id}}
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

### Block 17

```http alias=req17 timeout=30000
GET https://api.example.com/items?parent={{q16.response.body.name}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req15.response.body.name}}
Content-Type: application/json

{"ref": "{{q14.response.body.name}}", "page": 1}
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

### Block 18

```db-postgres alias=q18
SELECT id, name, created_at FROM items WHERE parent_id = {{req17.response.body.parent_id}} AND parent_id = {{q16.response.body.parent_id}} AND parent_id = {{req15.response.body.parent_id}} AND parent_id = {{q14.response.body.parent_id}}
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

### Block 19

```http alias=req19 timeout=30000
GET https://api.example.com/items?parent={{q18.response.body.owner_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req17.response.body.owner_id}}
Content-Type: application/json

{"ref": "{{q16.response.body.owner_id}}", "page": 1}
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

### Block 20

```db-postgres alias=q20
SELECT id, name, created_at FROM items WHERE status = {{req19.response.body.status}} AND status = {{q18.response.body.status}} AND status = {{req17.response.body.status}} AND status = {{q16.response.body.status}}
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

### Block 21

```http alias=req21 timeout=30000
GET https://api.example.com/items?parent={{q20.response.body.id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req19.response.body.id}}
Content-Type: application/json

{"ref": "{{q18.response.body.id}}", "page": 1}
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

### Block 22

```db-postgres alias=q22
SELECT id, name, created_at FROM items WHERE name = {{req21.response.body.name}} AND name = {{q20.response.body.name}} AND name = {{req19.response.body.name}} AND name = {{q18.response.body.name}}
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

### Block 23

```http alias=req23 timeout=30000
GET https://api.example.com/items?parent={{q22.response.body.parent_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req21.response.body.parent_id}}
Content-Type: application/json

{"ref": "{{q20.response.body.parent_id}}", "page": 1}
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

### Block 24

```db-postgres alias=q24
SELECT id, name, created_at FROM items WHERE owner_id = {{req23.response.body.owner_id}} AND owner_id = {{q22.response.body.owner_id}} AND owner_id = {{req21.response.body.owner_id}} AND owner_id = {{q20.response.body.owner_id}}
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

### Block 25

```http alias=req25 timeout=30000
GET https://api.example.com/items?parent={{q24.response.body.status}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req23.response.body.status}}
Content-Type: application/json

{"ref": "{{q22.response.body.status}}", "page": 1}
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

### Block 26

```db-postgres alias=q26
SELECT id, name, created_at FROM items WHERE id = {{req25.response.body.id}} AND id = {{q24.response.body.id}} AND id = {{req23.response.body.id}} AND id = {{q22.response.body.id}}
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

### Block 27

```http alias=req27 timeout=30000
GET https://api.example.com/items?parent={{q26.response.body.name}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req25.response.body.name}}
Content-Type: application/json

{"ref": "{{q24.response.body.name}}", "page": 1}
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

### Block 28

```db-postgres alias=q28
SELECT id, name, created_at FROM items WHERE parent_id = {{req27.response.body.parent_id}} AND parent_id = {{q26.response.body.parent_id}} AND parent_id = {{req25.response.body.parent_id}} AND parent_id = {{q24.response.body.parent_id}}
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

### Block 29

```http alias=req29 timeout=30000
GET https://api.example.com/items?parent={{q28.response.body.owner_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req27.response.body.owner_id}}
Content-Type: application/json

{"ref": "{{q26.response.body.owner_id}}", "page": 1}
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

### Block 30

```db-postgres alias=q30
SELECT id, name, created_at FROM items WHERE status = {{req29.response.body.status}} AND status = {{q28.response.body.status}} AND status = {{req27.response.body.status}} AND status = {{q26.response.body.status}}
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

### Block 31

```http alias=req31 timeout=30000
GET https://api.example.com/items?parent={{q30.response.body.id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req29.response.body.id}}
Content-Type: application/json

{"ref": "{{q28.response.body.id}}", "page": 1}
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

### Block 32

```db-postgres alias=q32
SELECT id, name, created_at FROM items WHERE name = {{req31.response.body.name}} AND name = {{q30.response.body.name}} AND name = {{req29.response.body.name}} AND name = {{q28.response.body.name}}
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

### Block 33

```http alias=req33 timeout=30000
GET https://api.example.com/items?parent={{q32.response.body.parent_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req31.response.body.parent_id}}
Content-Type: application/json

{"ref": "{{q30.response.body.parent_id}}", "page": 1}
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

### Block 34

```db-postgres alias=q34
SELECT id, name, created_at FROM items WHERE owner_id = {{req33.response.body.owner_id}} AND owner_id = {{q32.response.body.owner_id}} AND owner_id = {{req31.response.body.owner_id}} AND owner_id = {{q30.response.body.owner_id}}
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

### Block 35

```http alias=req35 timeout=30000
GET https://api.example.com/items?parent={{q34.response.body.status}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req33.response.body.status}}
Content-Type: application/json

{"ref": "{{q32.response.body.status}}", "page": 1}
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

### Block 36

```db-postgres alias=q36
SELECT id, name, created_at FROM items WHERE id = {{req35.response.body.id}} AND id = {{q34.response.body.id}} AND id = {{req33.response.body.id}} AND id = {{q32.response.body.id}}
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

### Block 37

```http alias=req37 timeout=30000
GET https://api.example.com/items?parent={{q36.response.body.name}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req35.response.body.name}}
Content-Type: application/json

{"ref": "{{q34.response.body.name}}", "page": 1}
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

### Block 38

```db-postgres alias=q38
SELECT id, name, created_at FROM items WHERE parent_id = {{req37.response.body.parent_id}} AND parent_id = {{q36.response.body.parent_id}} AND parent_id = {{req35.response.body.parent_id}} AND parent_id = {{q34.response.body.parent_id}}
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

### Block 39

```http alias=req39 timeout=30000
GET https://api.example.com/items?parent={{q38.response.body.owner_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req37.response.body.owner_id}}
Content-Type: application/json

{"ref": "{{q36.response.body.owner_id}}", "page": 1}
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

### Block 40

```db-postgres alias=q40
SELECT id, name, created_at FROM items WHERE status = {{req39.response.body.status}} AND status = {{q38.response.body.status}} AND status = {{req37.response.body.status}} AND status = {{q36.response.body.status}}
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

### Block 41

```http alias=req41 timeout=30000
GET https://api.example.com/items?parent={{q40.response.body.id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req39.response.body.id}}
Content-Type: application/json

{"ref": "{{q38.response.body.id}}", "page": 1}
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

### Block 42

```db-postgres alias=q42
SELECT id, name, created_at FROM items WHERE name = {{req41.response.body.name}} AND name = {{q40.response.body.name}} AND name = {{req39.response.body.name}} AND name = {{q38.response.body.name}}
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

### Block 43

```http alias=req43 timeout=30000
GET https://api.example.com/items?parent={{q42.response.body.parent_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req41.response.body.parent_id}}
Content-Type: application/json

{"ref": "{{q40.response.body.parent_id}}", "page": 1}
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

### Block 44

```db-postgres alias=q44
SELECT id, name, created_at FROM items WHERE owner_id = {{req43.response.body.owner_id}} AND owner_id = {{q42.response.body.owner_id}} AND owner_id = {{req41.response.body.owner_id}} AND owner_id = {{q40.response.body.owner_id}}
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

### Block 45

```http alias=req45 timeout=30000
GET https://api.example.com/items?parent={{q44.response.body.status}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req43.response.body.status}}
Content-Type: application/json

{"ref": "{{q42.response.body.status}}", "page": 1}
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

### Block 46

```db-postgres alias=q46
SELECT id, name, created_at FROM items WHERE id = {{req45.response.body.id}} AND id = {{q44.response.body.id}} AND id = {{req43.response.body.id}} AND id = {{q42.response.body.id}}
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

### Block 47

```http alias=req47 timeout=30000
GET https://api.example.com/items?parent={{q46.response.body.name}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req45.response.body.name}}
Content-Type: application/json

{"ref": "{{q44.response.body.name}}", "page": 1}
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

### Block 48

```db-postgres alias=q48
SELECT id, name, created_at FROM items WHERE parent_id = {{req47.response.body.parent_id}} AND parent_id = {{q46.response.body.parent_id}} AND parent_id = {{req45.response.body.parent_id}} AND parent_id = {{q44.response.body.parent_id}}
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

### Block 49

```http alias=req49 timeout=30000
GET https://api.example.com/items?parent={{q48.response.body.owner_id}}
Authorization: Bearer {{TOKEN}}
X-Parent-Id: {{req47.response.body.owner_id}}
Content-Type: application/json

{"ref": "{{q46.response.body.owner_id}}", "page": 1}
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

### Block 50

```db-postgres alias=q50
SELECT id, name, created_at FROM items WHERE status = {{req49.response.body.status}} AND status = {{q48.response.body.status}} AND status = {{req47.response.body.status}} AND status = {{q46.response.body.status}}
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

