// ==============================================
// ⚡ WIGGIES DATA PIPELINE ⚡
// ==============================================
// 🚀 Processes sales data from JSON, CSV, and API
// ✅ Cleans and normalizes data
// ✅ Computes total revenue, trends, and insights
// ✅ Outputs clean data for analytics

const fs = require("fs");
const csv = require("csv-parser");
const axios = require("axios");

// 📌 Source Files
const JSON_FILE = "sales.json";
const CSV_FILE = "sales.csv";
const API_URL = "https://api.example.com/sales";

// 📌 In-Memory Data Storage
let salesData = [];

// ==============================================
// 🔹 DATA INGESTION (READ JSON, CSV, API)
// ==============================================

// 📌 Load JSON Data
async function loadJSON() {
    try {
        const rawData = fs.readFileSync(JSON_FILE);
        const jsonData = JSON.parse(rawData);
        salesData.push(...jsonData);
        console.log("✅ JSON Data Loaded");
    } catch (error) {
        console.error("❌ Error loading JSON:", error);
    }
}

// 📌 Load CSV Data
async function loadCSV() {
    return new Promise((resolve, reject) => {
        fs.createReadStream(CSV_FILE)
            .pipe(csv())
            .on("data", (row) => salesData.push(row))
            .on("end", () => {
                console.log("✅ CSV Data Loaded");
                resolve();
            })
            .on("error", (error) => reject(error));
    });
}

// 📌 Fetch API Data
async function fetchAPIData() {
    try {
        const response = await axios.get(API_URL);
        salesData.push(...response.data);
        console.log("✅ API Data Fetched");
    } catch (error) {
        console.error("❌ API Fetch Error:", error);
    }
}

// ==============================================
// 🔹 DATA CLEANING & TRANSFORMATION
// ==============================================

// 📌 Convert string numbers to actual numbers
function normalizeData() {
    salesData = salesData.map((sale) => ({
        product: sale.product.trim(),
        category: sale.category.trim(),
        price: parseFloat(sale.price) || 0,
        quantity: parseInt(sale.quantity) || 0,
        date: new Date(sale.date),
        revenue: (parseFloat(sale.price) || 0) * (parseInt(sale.quantity) || 0),
    }));
    console.log("🔄 Data Normalized");
}

// 📌 Remove Duplicates
function removeDuplicates() {
    const uniqueSales = new Map();
    salesData.forEach((sale) => {
        const key = `${sale.product}-${sale.date.toISOString()}`;
        uniqueSales.set(key, sale);
    });
    salesData = Array.from(uniqueSales.values());
    console.log("🗑️ Duplicates Removed");
}

// 📌 Handle Missing Data
function handleMissingData() {
    salesData = salesData.filter((sale) => sale.product && sale.price && sale.quantity);
    console.log("⚡ Missing Data Handled");
}

// ==============================================
// 🔹 DATA AGGREGATION & ANALYSIS
// ==============================================

// 📌 Compute Total Revenue
function computeTotalRevenue() {
    return salesData.reduce((total, sale) => total + sale.revenue, 0);
}

// 📌 Get Top 5 Best-Selling Products
function getTopProducts() {
    const productSales = salesData.reduce((acc, sale) => {
        acc[sale.product] = (acc[sale.product] || 0) + sale.quantity;
        return acc;
    }, {});

    return Object.entries(productSales)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([product, quantity]) => ({ product, quantity }));
}

// 📌 Sales Trends (Daily Revenue)
function getSalesTrends() {
    const dailySales = salesData.reduce((acc, sale) => {
        const date = sale.date.toISOString().split("T")[0]; // Extract YYYY-MM-DD
        acc[date] = (acc[date] || 0) + sale.revenue;
        return acc;
    }, {});

    return Object.entries(dailySales).map(([date, revenue]) => ({ date, revenue }));
}

// ==============================================
// 🔹 EXPORT CLEANED DATA
// ==============================================

// 📌 Save Cleaned Data to JSON
function saveCleanedData() {
    fs.writeFileSync("cleaned_sales.json", JSON.stringify(salesData, null, 2));
    console.log("📂 Cleaned Data Saved!");
}

// 📌 Save Insights
function saveInsights() {
    const insights = {
        totalRevenue: computeTotalRevenue(),
        topProducts: getTopProducts(),
        salesTrends: getSalesTrends(),
    };

    fs.writeFileSync("sales_insights.json", JSON.stringify(insights, null, 2));
    console.log("📊 Insights Saved!");
}

// ==============================================
// 🔹 RUN PIPELINE
// ==============================================

// 📌 Main Execution
async function runPipeline() {
    console.log("🚀 Running Data Pipeline...");

    await Promise.all([loadJSON(), loadCSV(), fetchAPIData()]); // Load Data
    normalizeData(); // Transform
    removeDuplicates();
    handleMissingData();

    console.log("\n📊 Data Insights:");
    console.log(`💰 Total Revenue: $${computeTotalRevenue().toFixed(2)}`);
    console.log("🔥 Top 5 Best-Selling Products:", getTopProducts());
    console.log("📈 Sales Trends:", getSalesTrends().slice(0, 5)); // Show only top 5 trends

    saveCleanedData(); // Export Clean Data
    saveInsights(); // Save Insights
}

// Run Pipeline
runPipeline();
