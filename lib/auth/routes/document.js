const express = require('express');
const db = require('../db');
const router = express.Router();
const {authenticateToken} = require('../middleware/authMiddleware'); // path to middleware file


module.exports = router;