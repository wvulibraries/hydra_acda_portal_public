# ACDA Portal Documentation Wiki

Welcome to the American Congress Digital Archives Portal (ACDA) documentation wiki. Documentation is organized by purpose to help you find exactly what you need.

## 📚 Documentation by Purpose

### 🚀 Getting Started (Developer-Focused)
Since ACDA is maintained by the development team, documentation focuses on developer needs:

- **[Getting-Started-Quick-Start.md](Getting-Started-Quick-Start.md)** - Local development setup

### 🏗️ Architecture (Understand System Design)
See [architecture/](architecture/) for design decisions and system overview:
- Architecture-Decision-Records.md
- Hyrax-Alignment-Reference.md
- System-Architecture-Overview.md

### 👨‍💻 Developer Guides (Development, Setup & Configuration)
See [developer/](developer/) for all development work:
- Development-Guide.md - Development workflow
- Bulkrax-Configuration.md - Application setup and configuration
- Rake-Tasks-Implementation.md - Available maintenance tools

### 🎯 Planning & Strategy (Future Direction)
See [planning/](planning/) for roadmaps and strategic decisions:
- Modernization-Strategy.md - Long-term modernization
- Rails-8-Migration-Planning.md - Framework upgrade planning
- Bulk-Import-Strategy.md - Bulkrax and alternatives
- Bulkrax-Alternatives.md - Alternative solutions analysis

### ⚠️ Operations & Troubleshooting (Known Issues & Fixes)
See [operations/](operations/) for known issues and solutions:
- Known-Issues-And-Technical-Debt.md - Current blockers and limitations
- Fixing-Broken-Identifiers.md - Troubleshooting and repair procedures

## 🎯 By Role

### For Developers
1. Start with [[Quick Start Guide]]
2. Review [[System Architecture Overview]]
3. Check [[Development Guide]] for detailed setup
4. See [[Architecture Decision Records]] for design context

### For Operations
1. Review [[Deployment Guide]] (coming soon)
2. See [[Rails 8 Migration Planning]] for future planning
3. Check [[Troubleshooting]]

### For Decision Makers
1. Read [[Bulk Import Strategy]] for Bulkrax vs Spotlight decision
2. Review [[Architecture Decision Records]] for modernization context
3. See [[Rails 8 Migration Planning]] for resource planning

### For Data Import Specialists
1. Start with [[Bulkrax Configuration Guide]]
2. Review [[Field Mappings]]
3. See [[Fixing Broken Identifiers]] for remediation
4. Check [[Bulk Import Strategy]] for upgrade planning

## 📖 Documentation by Topic

### Project Context
- [[System Architecture Overview]] - Technical stack overview
- [[Hyrax Alignment]] - Community standards alignment
- [[Architecture Decision Records]] - Why we made certain choices

### Development Setup
- [[Quick Start Guide]] - 5-minute setup
- [[Development Guide]] - Comprehensive dev environment
- [[Docker & Local Development]] - Docker details
- [[Common Issues & Solutions]] - Troubleshooting

### Data & Imports
- **Current System**:
  - [[Bulkrax Configuration Guide]] - How the importer works
  - [[Field Mappings]] - Metadata field reference
  - [[Fixing Broken Identifiers]] - Data remediation
  
- **Future Planning**:
  - [[Bulk Import Strategy]] - v8 → v10 upgrade path
  - [[Bulkrax Alternatives]] - Other options evaluated

### Technical Decisions
- [[System Architecture Overview]] - Current tech stack
- [[Architecture Decision Records]] - Major decisions & rationale
- [[Hyrax Alignment]] - Modernization direction
- [[Rails 8 Migration Planning]] - Framework upgrade planning

### Maintenance & Operations
- [[Qwen Task: Rake Implementation]] - Automated tasks
- [[Common Issues & Solutions]] - Debugging & fixes
- [[Identifier & Thumbnail Issues]] - Data remediation guide

## 🚀 Current Status

**Framework**: Rails 7.0.8 (Ruby 3.3.5)  
**Planned**: Rails 8.0+ migration  
**Data Import**: Bulkrax v8.3.0 (custom Rails 7 branch)  
**Recommended Next**: Bulkrax v10.1 upgrade  

## 📋 Active Projects

- 🟡 **Bulkrax v10 Upgrade** - Proof of concept phase
- 🟡 **Rails 8 Migration** - Planning phase
- 🟢 **Identifier Remediation** - In progress
- 🟢 **Documentation Wiki** - Live (this site)

## 🔗 Important Links

**Production**: https://congressarchives.org  
**Development**: https://congressarchivesdev.lib.wvu.edu  
**GitHub**: https://github.com/wvulibraries/hydra_acda_portal_public  
**Samvera**: https://samvera.org  

## 📝 Contributing to Documentation

Documentation lives in `docs/wiki/` and uses Markdown format. To add or update documentation:

1. Create or edit a `.md` file in `docs/wiki/`
2. Follow the wiki page template (see existing pages)
3. Link from this Home page under appropriate section
4. Use `[[Page Name]]` wiki-style links to reference other pages
5. Submit PR with documentation changes

## ❓ Getting Help

- **Quick questions?** Check [[Common Issues & Solutions]]
- **Setting up dev?** See [[Quick Start Guide]]
- **Data import issues?** See [[Bulkrax Configuration Guide]]
- **Architecture questions?** See [[System Architecture Overview]]
- **Strategic decisions?** See [[Architecture Decision Records]]

## 📚 Full Page Index

| Page | Purpose |
|------|---------|
| **Quick Start Guide** | 5-minute application startup |
| **Development Guide** | Comprehensive dev environment setup |
| **System Architecture Overview** | Technical stack & components |
| **Architecture Decision Records** | Major design decisions & rationale |
| **Docker & Local Development** | Docker configuration details |
| **Hyrax Alignment** | Community standards alignment |
| **Bulk Import Strategy** | Bulkrax v10 upgrade analysis |
| **Bulkrax Configuration Guide** | OAI-PMH importer setup |
| **Field Mappings** | Metadata field reference |
| **Rails 8 Migration Planning** | Framework upgrade roadmap |
| **Bulkrax Alternatives** | Alternative import tools evaluated |
| **Fixing Broken Identifiers** | Identifier remediation guide |
| **Qwen Task: Rake Implementation** | Automated task framework |
| **Common Issues & Solutions** | Troubleshooting guide |

---

**Last Updated**: November 18, 2026  
**Status**: 🟢 Active Development  
**Maintained By**: WVU Libraries Development Team
