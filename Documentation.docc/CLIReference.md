# CLI Reference

## Commands

### museum:init
Create a new museum with wings.

```bash
musee museum:init <path.museum> [--wing <id>:<name>]...
```

Example:
```bash
musee museum:init ~/my-museum.museum --wing fitness "Fitness Journey" --wing career "Career Photos"
```

### museum:create-wing
Add a new wing to an existing museum.

```bash
musee museum:create-wing <museum.museum> <wing-id> <wing-name> [--desc <description>]
```

### museum:backup
Create an encrypted backup of a museum.

```bash
musee museum:backup <museum.museum> <backup.museum.enc>
```

### museum:restore
Restore a museum from an encrypted backup.

```bash
musee museum:restore <backup.museum.enc> <museum.museum>
```

### musee:validate
Validate a bundle's integrity.

```bash
musee musee:validate <path.musee>
```