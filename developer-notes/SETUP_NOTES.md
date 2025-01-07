# Dify Setup Notes

## Additional Configuration Notes

### Health Checks
- All core services have health checks configured with appropriate intervals and timeouts
- Database and Redis have short intervals (5s) for quick failure detection
- API and worker services have longer intervals (30s) to avoid false positives
- Vector stores have service-specific health checks

### Security Configurations
- AppArmor and SELinux profiles are provided in docker/apparmor and docker/selinux
- Default security settings follow best practices
- Dockerfile uses multi-stage builds to minimize attack surface
- All services run with minimal required privileges

### Development Environment
- Development environment includes additional debugging and testing tools
- Pre-commit hooks ensure code quality
- Local environment matches production as closely as possible
- Development database uses separate credentials

### Production Environment
- Production environment has additional security measures
- Logging is configured for production use
- Monitoring and alerting is enabled
- Backup and recovery procedures are tested

### Troubleshooting
1. Database Connection Issues:
   - Check database health with pg_isready
   - Verify connection settings in .env file
   - Check database logs for errors

2. Network Issues:
   - Run network check script
   - Verify all required ports are available
   - Check DNS resolution
   - Verify network interface configuration

3. Permission Issues:
   - Check volume permissions
   - Verify Docker socket permissions
   - Check SELinux/AppArmor settings

4. Resource Issues:
   - Monitor system resources with monitoring script
   - Check kernel parameters
   - Verify memory limits
   - Check disk space usage