// Backend ESLint Configuration - للحفاظ على جودة الكود
module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:node/recommended',
    'prettier', // يجب تثبيت eslint-config-prettier
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    // Error Prevention
    'no-console': 'warn', // تحذير عند استخدام console.log
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'no-var': 'error', // استخدم const/let فقط
    'prefer-const': 'error',
    
    // Code Quality
    'no-duplicate-imports': 'error',
    'no-template-curly-in-string': 'error',
    'require-await': 'error',
    
    // Best Practices
    'eqeqeq': ['error', 'always'], // استخدم === بدل ==
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-return-await': 'error',
    
    // Node.js Specific
    'node/no-unsupported-features/es-syntax': 'off',
    'node/no-missing-import': 'off',
    'node/no-unpublished-require': 'off',
  },
};
