# Assumptions and Design Decisions

## Project Assumptions

### Document Processing
1. **Document Types**: Only PDF and XLSX files need to be supported (as specified in requirements)
2. **Document Quality**: Documents are text-based PDFs (not scanned images requiring OCR)
3. **Single Shipment**: All uploaded documents relate to a single shipment
4. **Language**: Documents are in English

### Data Extraction
1. **Field Availability**: Not all fields may be present in every document
2. **Date Format**: Dates can be in various formats but will be normalized to MM/DD/YYYY
3. **Numeric Fields**: Line items count should be a number, weights and prices include units
4. **Multiple Items**: For averages, we calculate based on all line items found

### User Experience
1. **File Size**: Maximum 10MB per file (reasonable for typical shipping documents)
2. **Browser Support**: Modern browsers with ES6+ support
3. **Internet Connection**: Required for API calls to Anthropic
4. **Local Development**: Application runs on localhost for development/testing

## Design Decisions

### Architecture
- **Separated Backend/Frontend**: Clean separation of concerns
- **RESTful API**: Standard HTTP methods for clarity
- **Stateless API**: Each request is independent (no session management)

### Technology Choices
1. **FastAPI over Flask**:
   - Better async support
   - Automatic API documentation
   - Built-in validation with Pydantic

2. **React with Vite over CRA**:
   - Faster build times
   - Better developer experience
   - Smaller bundle size

3. **Claude 3.5 Sonnet**:
   - High accuracy for document understanding
   - Strong JSON output capabilities
   - Good balance of speed and quality

### Code Structure
- **Service Layer**: Separated business logic from API routes
- **Utility Functions**: Reusable code for PDF/XLSX processing
- **Component-Based UI**: Modular React components for maintainability

### Error Handling
- **Graceful Degradation**: Application continues working even if some fields fail to extract
- **User Feedback**: Clear error messages for debugging
- **Validation**: Both client-side and server-side validation

### Security (Development Mode)
- **CORS**: Open for development (should be restricted in production)
- **API Key**: Hardcoded for demo (should use environment variables)
- **File Upload**: Validated extensions and size limits
- **Temporary Files**: Cleaned up after processing

## Tradeoffs Made

### Performance vs Accuracy
- Chose Claude 3.5 Sonnet (mid-tier) for balance
- Could use Claude Opus for higher accuracy but slower/more expensive
- Could use Haiku for faster/cheaper but lower accuracy

### UI/UX vs Time
- Focused on core functionality over advanced features
- Clean, professional design over flashy animations
- Responsive layout for desktop/tablet (mobile deprioritized)

### Features Prioritized
**Included**:
- Document upload with drag-and-drop
- AI extraction with all 8 required fields
- Editable form with validation
- Document viewer for PDFs
- Error handling and user feedback

**Deferred** (would add with more time):
- User authentication
- Database persistence
- OCR for scanned documents
- Advanced document preview features
- Export functionality (CSV, JSON)
- Batch processing
- Document history/versioning

## Known Issues
1. **XLSX Preview**: Browsers cannot natively render Excel files, so we show a download option instead
2. **Large PDFs**: Very large files may cause timeout issues
3. **Complex Layouts**: Multi-column or table-heavy PDFs may have extraction challenges

## Production Readiness Considerations

To make this production-ready, we would need:

1. **Environment Configuration**:
   - Move API keys to environment variables
   - Add production/staging/development configs
   - Set up proper CORS origins

2. **Database Integration**:
   - Store extracted data
   - Track document processing history
   - User session management

3. **Authentication & Authorization**:
   - User login system
   - API key management
   - Role-based access control

4. **Monitoring & Logging**:
   - Application performance monitoring
   - Error tracking (e.g., Sentry)
   - Audit logs

5. **Testing**:
   - Unit tests for backend services
   - Integration tests for API endpoints
   - E2E tests for frontend flows
   - Load testing for scalability

6. **Deployment**:
   - Docker containers
   - CI/CD pipeline
   - Cloud hosting (AWS, GCP, Azure)
   - CDN for frontend assets

7. **Security**:
   - HTTPS only
   - Rate limiting
   - Input sanitization
   - Security headers

## Time Allocation

Approximate time spent on each component:

- **Setup & Planning**: 15 minutes
- **Backend Development**: 45 minutes
  - API routes and file handling: 15 min
  - LLM integration: 15 min
  - Document processing: 15 min
- **Frontend Development**: 60 minutes
  - Components: 30 min
  - Styling: 20 min
  - Integration: 10 min
- **Testing & Debugging**: 30 minutes
- **Documentation**: 20 minutes

**Total**: ~2.5 hours (within the 3-hour timeframe)

## Future Recommendations

1. **Add OCR**: For scanned/image-based PDFs
2. **Improve Extraction**: Fine-tune prompts for specific document types
3. **Add Caching**: Cache extracted data to reduce API costs
4. **Webhooks**: Support async processing for large batches
5. **Templates**: Allow users to define custom extraction templates
6. **Multi-language**: Support for documents in different languages
7. **Data Validation**: Business logic validation (e.g., container number format)
8. **Analytics**: Track extraction accuracy and common errors
