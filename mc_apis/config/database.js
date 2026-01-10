/**
 * MySQL Database Configuration
 */

const mysql = require('mysql2/promise');
require('dotenv').config();

// Database connection pool with improved error handling
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'mindcoach',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  // Connection timeout settings - increased for better reliability
  acquireTimeout: 90000, // 90 seconds - connection pool'dan connection almak için max bekleme süresi
  timeout: 90000, // 90 seconds - query timeout
  // Connection retry settings
  reconnect: true,
  // Additional connection options
  connectTimeout: 30000, // 30 seconds - initial connection timeout
  // Keep connections alive
  idleTimeout: 300000, // 5 minutes - idle connection timeout
});

// Test connection with retry mechanism
async function testConnection(retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const connection = await pool.getConnection();
      console.log('✅ MySQL database connected successfully');
      connection.release();
      return;
    } catch (error) {
      console.error(`❌ MySQL database connection error (attempt ${i + 1}/${retries}):`, error.message);
      if (i < retries - 1) {
        console.log('🔄 Retrying connection in 2 seconds...');
        await new Promise(resolve => setTimeout(resolve, 2000));
      } else {
        console.error('❌ Failed to connect to MySQL database after', retries, 'attempts');
        console.error('Please check your database configuration in .env file');
      }
    }
  }
}

// Test connection on startup
testConnection();

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('🔄 Closing MySQL connection pool...');
  await pool.end();
  console.log('✅ MySQL connection pool closed');
  process.exit(0);
});

module.exports = pool;

