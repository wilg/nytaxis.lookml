- connection: bigquery

- include: "*.view.lookml"       # include all the views
- include: "*.dashboard.lookml"  # include all the dashboards

- persist_for: 5000 hours