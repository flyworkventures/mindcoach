/**
 * Database Retry Utility
 * Provides retry mechanism for database operations that may fail due to connection issues
 */

const pool = require('../config/database');

/**
 * Execute a database query with retry mechanism
 * @param {Function} queryFn - Function that returns a promise with the query result
 * @param {number} retries - Number of retries (default: 2)
 * @param {string} operationName - Name of the operation for logging
 * @returns {Promise<any>} Query result
 */
async function executeWithRetry(queryFn, retries = 2, operationName = 'Database operation') {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await queryFn();
    } catch (error) {
      // Retry on connection errors
      const isRetryableError = 
        error.code === 'ECONNRESET' ||
        error.code === 'PROTOCOL_CONNECTION_LOST' ||
        error.code === 'ETIMEDOUT' ||
        error.code === 'ECONNREFUSED' ||
        error.code === 'ENOTFOUND' ||
        (error.message && error.message.includes('Connection lost'));
      
      if (isRetryableError && attempt < retries) {
        const delay = Math.min(200 * (attempt + 1), 2000); // Exponential backoff, max 2 seconds
        console.warn(`⚠️ [DB-RETRY] ${operationName} failed (attempt ${attempt + 1}/${retries + 1}), retrying in ${delay}ms...`, error.code || error.message);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      
      // Last attempt or non-retryable error
      console.error(`❌ [DB-RETRY] ${operationName} failed after ${attempt + 1} attempts:`, error);
      throw error;
    }
  }
}

/**
 * Execute a pool.execute query with retry
 * @param {string} sql - SQL query
 * @param {Array} params - Query parameters
 * @param {number} retries - Number of retries
 * @param {string} operationName - Name of the operation
 * @returns {Promise<Array>} Query result
 */
async function executeWithRetryQuery(sql, params = [], retries = 2, operationName = 'Query') {
  return executeWithRetry(
    () => pool.execute(sql, params),
    retries,
    operationName
  );
}

module.exports = {
  executeWithRetry,
  executeWithRetryQuery
};
