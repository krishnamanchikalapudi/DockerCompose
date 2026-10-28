CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS petclinic_vector_store (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    metadata JSONB,
    embedding vector(768) NOT NULL -- 768 for nomic-embed-text / Gemini text-embedding-004
);

-- HNSW index for sub-millisecond approximate nearest neighbor search
CREATE INDEX IF NOT EXISTS petclinic_vector_hnsw_idx 
ON petclinic_vector_store USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- GIN index for fast JSONB metadata filtering (e.g., petType, vetId, category)
CREATE INDEX IF NOT EXISTS petclinic_metadata_gin_idx 
ON petclinic_vector_store USING gin (metadata);

-- Full text search index for sparse retrieval
CREATE INDEX IF NOT EXISTS petclinic_content_fts_idx 
ON petclinic_vector_store USING gin (to_tsvector('english', content));