# MoomooMarkets

## Overview

MoomooMarkets is a web application that integrates with various financial data providers to offer comprehensive market analysis tools.

## Features

### Authentication System
- User registration and login
- Secure password hashing with bcrypt
- Session-based authentication

### Data Source Integration
- J-Quants API Integration
  - Token-based authentication
  - Automatic token refresh mechanism
  - Secure credential storage with encryption
  - Comprehensive test coverage for authentication flow

## Development Setup

### Prerequisites
- Elixir 1.15 or later
- Phoenix Framework
- PostgreSQL
- Environment variables (see below)

### Installation

1. Clone the repository
```bash
git clone [repository-url]
cd moomoo_markets
```

2. Install dependencies
```bash
mix setup
```

3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Create and migrate database
```bash
mix ecto.setup
```

5. Start Phoenix server
```bash
mix phx.server
# or inside IEx
iex -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

Run the test suite:
```bash
mix test
```

## Implementation Status

### Completed
- [x] Basic user authentication
- [x] Database schema for users and credentials
- [x] J-Quants API integration
  - [x] Token management system
  - [x] Automatic token refresh
  - [x] Secure credential storage
  - [x] Test coverage with Bypass

### In Progress
- [ ] Market data retrieval
- [ ] User interface for data visualization
- [ ] Additional data source integrations

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [J-Quants API Documentation](https://jpx.gitbook.io/j-quants-api/)
