## Platform Supabase DB

This repository contains the database schema and migrations for the Amari platform, integrated with Supabase to support database branching functionality. 

### Overview

The platform-db repository manages:
- Database schema definitions
- Migration scripts for schema changes
- Supabase integration for seamless database branching
- Development and production environment configurations

### Features

- **Database Branching**: Leverage Supabase's branching capabilities to create isolated database environments for feature development and testing
- **Schema Management**: Version-controlled database schema with automated migrations
- **Environment Support**: Separate configurations for development, staging, and production environments
- **Type Safety**: Generated TypeScript types from database schema for frontend integration

### Getting Started

1. Clone the repository
2. Install dependencies
3. Configure Supabase connection
4. Run migrations to set up your database schema
5. Create feature branches as needed for development

This setup enables teams to work on database changes in isolation while maintaining consistency across environments.