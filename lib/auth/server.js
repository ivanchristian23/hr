const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const leavesRoutes = require('./routes/leaves');
const managersRoutes = require('./routes/managers');
const passwordResetRoutes = require('./routes/passwordReset');
const documentRoutes = require('./routes/document')
const newsletterRoutes = require('./routes/newsletter')
const raiseRequestRoutes =require('./routes/raise_request')

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Register all routes
app.use('/auth', authRoutes);
app.use('/users', usersRoutes);
app.use('/leaves', leavesRoutes);
app.use('/managers', managersRoutes);
app.use('/password', passwordResetRoutes);
app.use('/documents', documentRoutes);
app.use('/newsletter', newsletterRoutes);
app.use('/raiserequest',raiseRequestRoutes)

app.listen(3000, () => console.log('✅ Server running at http://localhost:3000'));
