# JXQZ - Image Gallery Website Generator

A collection of bash scripts for generating static HTML image galleries with thumbnail support.

**Website:** [http://jxqz.org/](http://jxqz.org/)

## Scripts Overview

### `jxqz.sh` - Original Hand-Written Script
**Author:** Steve Buer (2023)  
**Status:** Preserved for posterity and reference

The original, carefully crafted script that serves as the foundation and reference implementation. This script remains untouched to preserve the original design and implementation approach.

### `jxqz-auto.sh` - AI-Generated Enhanced Version
**Generated:** October 20, 2025  
**Based on:** Original jxqz.sh

An AI-enhanced version that maintains full backward compatibility while adding modern features, better error handling, and improved user experience.

## Features Comparison

| Feature | jxqz.sh | jxqz-auto.sh |
|---------|---------|--------------|
| HTML Generation | ✅ Basic | ✅ Modern HTML5 + CSS |
| File Renaming | ✅ | ✅ Enhanced validation |
| Image Rotation | ✅ Placeholder | ✅ Full implementation |
| Thumbnail Creation | ✅ | ✅ Enhanced |
| Error Handling | Basic | ✅ Comprehensive |
| Help System | Basic | ✅ Detailed with examples |
| Input Validation | Minimal | ✅ Robust |
| Cross-platform Support | ✅ | ✅ ImageMagick variants |

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/stevebuer/jxqz.git
   cd jxqz
   ```

2. Make scripts executable:
   ```bash
   chmod +x jxqz.sh jxqz-auto.sh
   ```

3. Ensure ImageMagick is installed:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install imagemagick
   
   # macOS
   brew install imagemagick
   
   # RHEL/CentOS/Fedora
   sudo yum install ImageMagick
   ```

## Usage

Both scripts use the same basic command structure and read filenames from stdin.

### Quick Start Examples

```bash
# List your image files and generate thumbnails
ls *.jpg | ./jxqz-auto.sh thumb

# Create an HTML gallery page
ls *.jpg | ./jxqz-auto.sh gen "My Photos" "Summer Vacation"

# Rename files with a common prefix
ls *.jpg | ./jxqz-auto.sh ren vacation

# Rotate images 90 degrees clockwise
ls *.jpg | ./jxqz-auto.sh rot
```

### Commands Reference

#### `gen` - Generate HTML Gallery
Creates an HTML page with linked thumbnails.

**Original syntax:**
```bash
ls *.jpg | ./jxqz.sh gen
```

**Enhanced syntax:**
```bash
ls *.jpg | ./jxqz-auto.sh gen [title] [heading]
```

**Examples:**
```bash
# Basic generation
ls *.jpg | ./jxqz-auto.sh gen

# With custom title and heading
ls *.jpg | ./jxqz-auto.sh gen "My Gallery" "Photo Collection"
```

#### `ren` - Rename Files
Renames files with sequential numbering.

**Syntax:**
```bash
ls *.jpg | ./jxqz-auto.sh ren <basename>
```

**Example:**
```bash
ls IMG_*.jpg | ./jxqz-auto.sh ren vacation
# Results: vacation1.jpg, vacation2.jpg, vacation3.jpg, ...
```

#### `thumb` - Create Thumbnails
Generates thumbnail images in a `thumbs/` directory.

**Original syntax:**
```bash
ls *.jpg | ./jxqz.sh thumb
```

**Enhanced syntax:**
```bash
ls *.jpg | ./jxqz-auto.sh thumb [size]
```

**Examples:**
```bash
# Default 175x175 thumbnails
ls *.jpg | ./jxqz-auto.sh thumb

# Custom size thumbnails
ls *.jpg | ./jxqz-auto.sh thumb 200x200
```

#### `rot` - Rotate Images
Rotates images by specified degrees.

**Enhanced syntax:**
```bash
ls *.jpg | ./jxqz-auto.sh rot [degrees]
```

**Examples:**
```bash
# Default 90° clockwise rotation
ls *.jpg | ./jxqz-auto.sh rot

# Custom rotation
ls *.jpg | ./jxqz-auto.sh rot 180
ls *.jpg | ./jxqz-auto.sh rot -90  # Counter-clockwise
```

### Help System

Get detailed usage information:
```bash
./jxqz-auto.sh help
```

## Typical Workflow

1. **Organize your images** in a directory
2. **Create thumbnails:**
   ```bash
   ls *.jpg | ./jxqz-auto.sh thumb
   ```
3. **Generate the HTML gallery:**
   ```bash
   ls *.jpg | ./jxqz-auto.sh gen "My Gallery" "Collection Name" > gallery.html
   ```
4. **Optional: Rename files** for consistency:
   ```bash
   ls IMG_*.jpg | ./jxqz-auto.sh ren photo
   ```

## Output Structure

The scripts create the following structure:
```
your-directory/
├── *.jpg              # Original images
├── thumbs/             # Generated thumbnails
│   └── *_t.jpg
└── gallery.html        # Generated HTML (when redirected)
```

## Web Server Deployment

The generated HTML galleries are designed to work with **Apache2** web servers. The static HTML files can be directly served without any server-side processing requirements.

### Production Environment
- **Server OS:** Debian Linux
- **Web Server:** Apache2
- **Mail Server:** Dovecot (IMAP)
- **Hosting:** Vultr
- **Primary Site:** [http://jxqz.org/](http://jxqz.org/)
- **Analytics Application:** dx.jxqz.org (full-stack database-driven)
- **Additional Domains:** arpoison.net, suoc.org (small static sites)
- **Development/Temporary:** `~steve/public_html/` directory for miscellaneous files and temporary work

### Apache2 Configuration Notes:
- Ensure `.htaccess` files are allowed if using custom redirects
- The `thumbs/` directory should be web-accessible
- Image files should have appropriate MIME types configured
- Consider enabling `mod_rewrite` for clean URLs if desired
- User directories (`public_html`) should be enabled for development work

### Deployment Workflow:
1. Generate galleries locally using the scripts
2. Upload to main site directory or `~steve/public_html/` for testing
3. Ensure proper file permissions for web server access
4. Test gallery functionality before moving to production

### Disaster Recovery
For complete system recovery within 24 hours, maintain local copies of:
- **Apache2 configuration files** (`/etc/apache2/`)
- **Site content** (synced via rsync)
- **SSL certificates** (if applicable)
- **System configuration** relevant to web serving

Consider creating a `config/` directory in this repository to store sanitized Apache configuration files for quick recovery.

## Dependencies

- **Bash** (any recent version)
- **ImageMagick** (`convert` or `magick` command)
  - Used for thumbnail generation and image rotation
  - Cross-platform support for both legacy and modern ImageMagick installations

## Development Philosophy

This repository demonstrates the relationship between hand-crafted and AI-generated code:

- **`jxqz.sh`** represents thoughtful, manual implementation with clear intent
- **`jxqz-auto.sh`** shows how AI can enhance functionality while preserving the original design
- Both scripts coexist, allowing comparison and choice based on needs

### Project Approach

This is an **old school 1990s-style website** with purely static content, maintained using traditional Unix tools:

- **Core Tools:** `ssh`, `rsync`, `bash`, and `make`
- **Philosophy:** Simple, reliable, static content generation
- **Architecture:** Local development mirror that serves as both workspace and backup
- **Backup Strategy:** Annual DVD burns of complete file tree for long-term preservation
- **Deployment:** Direct file synchronization between local and production environments

### Development Workflow

1. **Local Development:** Generate and test galleries on laptop
2. **Synchronization:** Use `rsync` to deploy changes to production server
3. **Backup Cycle:** Create annual DVD archives of complete site
4. **Version Control:** Git for script development, file-based for content

This approach prioritizes simplicity, reliability, and long-term maintainability over modern web development complexity.

## Modern DevOps Integration

While maintaining the traditional Unix approach, this project can serve as a foundation for learning modern DevOps practices:

### Infrastructure as Code (Terraform)

**Terraform** is perfect for your situation and career development goals:

**Immediate Applications:**
- **Multi-provider deployment:** Easily move from Vultr to AWS, DigitalOcean, or other providers
- **Environment scaling:** Create staging/production environments with identical configurations
- **Multi-domain management:** Configure jxqz.org, dx.jxqz.org, arpoison.net, suoc.org with consistent setup
- **DNS automation:** Manage DNS records through Infrastructure as Code instead of manual registrar changes
- **Disaster recovery:** Provision new servers with identical setup in minutes
- **Cost optimization:** Spin up/down resources as needed for your full-stack analytics application

**Career Benefits:**
- High demand skill (mentioned in most DevOps job postings)
- Bridges traditional sysadmin experience with modern cloud practices
- Transferable across all major cloud providers
- Complements your existing `bash`, `ssh`, and `rsync` skills

### Suggested Learning Path

1. **Start Small:** Use Terraform to define your current Vultr server configuration
2. **Expand:** Create modules for your Apache setup, database server (for analytics app)
3. **Scale:** Deploy multiple environments (dev/staging/prod)
4. **Portfolio:** Document the transformation from manual to Infrastructure as Code

### Modern Stack Integration

Your current projects provide excellent learning opportunities:

**Static Site (jxqz.org):**
- Terraform for server provisioning
- Ansible for configuration management
- CI/CD pipeline for automated deployment
- CDN integration for performance

**Database Analytics Application:**
- Terraform for database infrastructure
- Docker containers for application deployment
- Load balancers for scaling
- Monitoring and logging setup

### Skill Bridge Strategy

Leverage your 20-year Linux sysadmin experience:
- **Your strength:** Deep understanding of Linux internals, networking, security
- **New layer:** Automation, orchestration, and cloud-native practices
- **Advantage:** Many DevOps engineers lack your foundational knowledge

This combination of traditional Unix skills + modern DevOps tools is highly valuable in the job market.

## Contributing

The original `jxqz.sh` is preserved as a reference and should not be modified. Improvements and new features should be implemented in `jxqz-auto.sh` or new variants.

## License

See [LICENSE](LICENSE) file for details.

## History

- **2023**: Original `jxqz.sh` created by Steve Buer
- **October 2025**: AI-generated `jxqz-auto.sh` created with enhanced features