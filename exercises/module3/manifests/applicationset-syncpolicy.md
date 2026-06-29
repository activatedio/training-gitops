# The `default` ApplicationSet sync policy

The bootstrap template (`github.com/activatedio/argocd-bootstrap`) ships a
`default` ApplicationSet in `projects/default.yaml`. It turns every directory
under `apps/*` into an ArgoCD `Application`, and its `template.spec.syncPolicy`
decides whether those apps sync automatically or wait for a manual Sync.

These exercises drive the sync **by hand first** (so you review every diff in
the UI before it lands), then switch automation on. Both states are just edits
to the same block, committed to Git.

## Automatic (how the template ships)

```yaml
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - ServerSideApply=true
          - CreateNamespace=true
```

## Manual (Step 4 — remove the `automated` block)

```yaml
      syncPolicy:
        syncOptions:
          - ServerSideApply=true
          - CreateNamespace=true
```

`03-manual-first.sh` makes this edit for you; `06-enable-autosync.sh` puts the
`automated` block back (Step 7). Each is a single commit the `root` Application
reconciles.
