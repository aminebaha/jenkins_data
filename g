name: Comment on PR with Images

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  comment-on-pr:
    runs-on: ubuntu-latest

    steps:
    # 1. Checkout repository
    - name: Checkout repository
      uses: actions/checkout@v3

    # 2. Trouver tous les fichiers dependency-graph.svg
    - name: Find dependency-graph.svg files
      id: find_files
      run: |
        # Cherche tous les fichiers dependency-graph.svg et les stocke dans une variable
        files=$(find . -name "dependency-graph.svg")
        echo "files=$files" >> $GITHUB_ENV

    # 3. Commenter la PR avec les liens des images
    - name: Comment on PR with images
      uses: actions/github-script@v6
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        script: |
          const pr_number = context.payload.pull_request.number;

          // Récupération des fichiers trouvés
          const files = process.env.files.split("\n").filter(file => file !== "");

          // Vérifier s'il y a des fichiers
          if (files.length === 0) {
            core.setFailed("Aucun fichier 'dependency-graph.svg' trouvé.");
          }

          // Construction du body du commentaire avec les images trouvées
          let body = "### Dependency Graphs trouvés :\n\n";
          
          files.forEach((file, index) => {
            const imageUrl = `${file.replace('./', '')}`;  // Corrige le chemin pour être relatif
            body += `![Dependency Graph ${index + 1}](./${imageUrl})\n\n`;  // Ajoute chaque image au body
          });

          // Poster le commentaire dans la PR
          await github.issues.createComment({
            owner: context.repo.owner,
            repo: context.repo.repo,
            issue_number: pr_number,
            body: body
          });
