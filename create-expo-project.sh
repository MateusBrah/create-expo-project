#!/bin/bash

# Solicita o nome do projeto
read -p "Digite o nome do projeto: " projectName

# Cria a pasta do projeto
mkdir $projectName

# Entra no diretório do projeto
cd $projectName

# Cria o projeto com Expo usando o template default
npx create-expo-app@latest --template default .

# Configura o tsconfig.json
cat > tsconfig.json << EOL
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "jsx": "react-jsx",
    "strict": true,
    "paths": {
      "@/*": [
        "./src/*"
      ]
    }
  },
  "include": [
    "**/*.ts",
    "**/*.tsx",
    ".expo/types/**/*.ts",
    "expo-env.d.ts"
  ]
}
EOL

# Adiciona o script ao package.json
npm pkg set scripts.create-view="node src/scripts/createPage.js"

# Cria as pastas necessárias dentro de src
mkdir -p src/{app,assets,components,constants,hooks,scripts,views,@types,services}

# Move as pastas criadas pelo Expo para dentro de src
mv app assets components constants hooks src/

# Cria o arquivo createPage.js dentro da pasta scripts
cat > src/scripts/createPage.js << 'EOL'
const fs = require("fs");
const path = require("path");
const readline = require("readline");

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function generatePage(name, hasForm) {
  const pagesPath = path.join("src/views");

  const pageName = name.toLowerCase();
  const view = `${pageName[0].toUpperCase()}${pageName.slice(1)}View`;
  const viewModel = `useView`;
  const models = `models`;

  if (!fs.existsSync(pagesPath)) {
    fs.mkdirSync(pagesPath, { recursive: true });
  }

  const pageFolderPath = path.join(pagesPath, pageName);

  if (!fs.existsSync(pageFolderPath)) {
    fs.mkdirSync(pageFolderPath, { recursive: true });

    const hooksFolderPath = path.join(pageFolderPath, "models");
    if (!fs.existsSync(hooksFolderPath)) {
      fs.mkdirSync(hooksFolderPath, { recursive: true });
    }

    const files = [
      `view.tsx`,
      `${pageName}.styles.ts`,
      path.join("models", `${viewModel}.model.ts`),
      path.join("models", `${models}.ts`)
    ];

    if (hasForm.toLowerCase() === "sim") {
      const formFolderPath = path.join(pageFolderPath, "hooks");
      if (!fs.existsSync(formFolderPath)) {
        fs.mkdirSync(formFolderPath, { recursive: true });
      }
      files.push(path.join("hooks", `${pageName}.schema.ts`));
    }

    files.forEach((file) => {
      const filePath = path.join(pageFolderPath, file);
      if (file.endsWith(".tsx")) {
        const fileContent = `import React from "react";
import { View, Text } from "react-native";
import { styles } from "./${pageName}.styles";
import { ${viewModel} } from "./models/${viewModel}.model";

export function ${view}() {
  const { /* hook state */ } = ${viewModel}();

  return (
    <View style={styles.root}>
      <Text style={styles.title}>${pageName}</Text>
    </View>
  );
}`;
        fs.writeFileSync(filePath, fileContent);
      } else if (file.endsWith("styles.ts")) {
        const fileContent = `import { StyleSheet } from 'react-native';

export const styles = StyleSheet.create({
  root: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
  },
});`;
        fs.writeFileSync(filePath, fileContent);
      } else if (file.endsWith("models.ts")) {
        const fileContent = `export interface ${view}Model {};`;
        fs.writeFileSync(filePath, fileContent);
      } else if (file.endsWith(".schema.ts")) {
        const fileContent = `import { z } from 'zod';

export const ${pageName}Schema = z.object({
  // Add your form schema here
});

export function ${pageName}FormDefaultValues() {
  return {
    // Add your default values here
  };
};`;
        fs.writeFileSync(filePath, fileContent);
      } else {
        const fileContent = `import { ${view}Model } from './models';

export const ${viewModel} = (): ${view}Model => {
  // Hooks logic here
  return {};
};`;
        fs.writeFileSync(filePath, fileContent);
      }
    });

    console.log(
      `Página '${pageName}' criada com sucesso em '${pageFolderPath}'.`
    );
  } else {
    console.log(`A página '${pageName}' já existe em '${pageFolderPath}'.`);
  }
}

rl.question("Digite o nome da página que deseja criar: ", (pageName) => {
  rl.question("A página terá um formulário? (sim/não): ", (hasForm) => {
    generatePage(pageName, hasForm);
    rl.close();
  });
});
EOL

rm -rf scripts

# Atualiza o app.json com os novos caminhos
if command -v jq &> /dev/null
then
  jq '.expo.icon = "./src/assets/images/icon.png" |
      .expo.splash.image = "./src/assets/images/splash.png" |
      .expo.android.adaptiveIcon.foregroundImage = "./src/assets/images/adaptive-icon.png" |
      .expo.web.favicon = "./src/assets/images/favicon.png"' app.json > temp.json && mv temp.json app.json
else
  echo "Por favor, instale o jq para atualizar o app.json"
fi

# Instala as dependências zod e react-hook-form
yarn add zod react-hook-form

echo "##### Tudo certo #####
Obrigado por usar o meu script! 🚀
github: MateusBrah
linkedin: https://www.linkedin.com/in/mateusdamasceno/
"
