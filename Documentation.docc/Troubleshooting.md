# Troubleshooting

## Common Issues

### Build Errors
- Ensure Xcode 14+ and Swift 5.7+
- Check module dependencies

### Vision Processing Failures
- Verify image format support
- Check for sufficient lighting
- Ensure camera permissions

### Search Not Returning Results
- Verify indexing completed
- Check query parameters
- Ensure assets have metadata

## Debug Commands

```bash
# Validate bundle
musee musee:validate bundle.musee

# Check museum structure
ls -la museum.museum/
```