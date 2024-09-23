const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();

// Middleware
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

// Set view engine to EJS
app.set('view engine', 'ejs');

// Render registration form
app.get('/register', (req, res) => {
  res.render('register');
});

// Handle form submission
app.post('/register', (req, res) => {
  const { name, email, password } = req.body;
  // Here you'd handle registration logic (e.g., save to a database)
  res.send(\`User \${name} registered with email \${email}\`);
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(\`Server running on port \${PORT}\`));
