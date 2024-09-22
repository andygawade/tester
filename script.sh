#!/bin/bash

# Set up project directory
PROJECT_DIR="email-registration"
echo "Setting up project in '$PROJECT_DIR'..."
mkdir $PROJECT_DIR
cd $PROJECT_DIR

# Initialize Node.js project
echo "Initializing Node.js project..."
npm init -y

# Install required dependencies
echo "Installing dependencies..."
npm install express mongoose bcryptjs body-parser

# Create necessary folders
echo "Creating folders..."
mkdir -p models routes

# Create User model
echo "Creating User model..."
cat > models/User.js <<EOL
const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
  },
  date: {
    type: Date,
    default: Date.now,
  },
});

const User = mongoose.model('User', UserSchema);
module.exports = User;
EOL

# Create authentication routes
echo "Creating authentication routes..."
cat > routes/auth.js <<EOL
const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const router = express.Router();

// @route   POST /api/register
// @desc    Register user with email and password
router.post('/register', async (req, res) => {
  const { email, password } = req.body;

  // Simple validation
  if (!email || !password) {
    return res.status(400).json({ msg: 'Please enter all fields' });
  }

  try {
    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ msg: 'User already exists' });
    }

    // Create new user instance
    user = new User({
      email,
      password,
    });

    // Hash password before saving
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);

    // Save user to the database
    await user.save();

    res.status(201).json({ msg: 'User registered successfully', userId: user.id });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
EOL

# Create main server file
echo "Creating main server file..."
cat > server.js <<EOL
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/auth');

// Initialize the app
const app = express();

// Middleware
app.use(bodyParser.json()); // for parsing application/json

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/yourdbname', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  useCreateIndex: true,
})
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log(err));

// Use routes
app.use('/api', authRoutes);

// Listen on port
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(\`Server running on port \${PORT}\`));
EOL

# Completion message
echo "Project setup complete. Run 'npm start' to start the server."

