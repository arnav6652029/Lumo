const express = require("express");
const mysql = require("mysql2/promise");
const bcrypt = require("bcrypt");

const app = express();

app.use(express.json());
app.use(express.static(__dirname));

let db;

/* ------------------ MYSQL SETUP ------------------ */

async function initializeDatabase() {

    const connection = await mysql.createConnection({
        host: "localhost",
        user: "root",
        password: "Arnav@1234"
    });

    await connection.query(`
        CREATE DATABASE IF NOT EXISTS Users
    `);

    await connection.end();

    db = await mysql.createConnection({
        host: "localhost",
        user: "root",
        password: "Arnav@1234",
        database: "Users"
    });

    await db.query(`
        CREATE TABLE IF NOT EXISTS users (

            id INT AUTO_INCREMENT PRIMARY KEY,

            name VARCHAR(255) NOT NULL,

            email VARCHAR(255) NOT NULL UNIQUE,

            password VARCHAR(255) NOT NULL,

            mobile VARCHAR(50),

            Hinduism BOOLEAN DEFAULT FALSE,
            Buddhism BOOLEAN DEFAULT FALSE,
            Christianity BOOLEAN DEFAULT FALSE,
            Islam BOOLEAN DEFAULT FALSE,
            Judaism BOOLEAN DEFAULT FALSE,
            Other BOOLEAN DEFAULT FALSE,

            created_at TIMESTAMP
            DEFAULT CURRENT_TIMESTAMP

        )
    `);

    console.log("MySQL Ready");
}

/* ------------------ SIGNUP ------------------ */

app.post("/signup", async (req, res) => {

    try {

        const {
            name,
            email,
            password,
            mobile,
            religions
        } = req.body;

        const [existing] = await db.query(
            "SELECT * FROM users WHERE email = ?",
            [email]
        );

        if (existing.length > 0) {

            return res.json({
                success: false,
                message: "Email already registered"
            });
        }

        const hashedPassword =
            await bcrypt.hash(password, 10);

        await db.query(

            `INSERT INTO users (

                name,
                email,
                password,
                mobile,

                Hinduism,
                Buddhism,
                Christianity,
                Islam,
                Judaism,
                Other

            )

            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [

                name,
                email,
                hashedPassword,
                mobile,

                religions.includes("Hinduism"),
                religions.includes("Buddhism"),
                religions.includes("Christianity"),
                religions.includes("Islam"),
                religions.includes("Judaism"),
                religions.includes("Other")

            ]
        );

        res.json({
            success: true,
            message: "Signup successful"
        });

    } catch (err) {

        console.error(err);

        res.json({
            success: false,
            message: "Server error"
        });
    }
});

app.post("/favourites/add", async (req, res) => {

    const { userId, templeId } = req.body;

    try {

        await db.execute(
            `
            INSERT IGNORE INTO favourite_temples
            (user_id, temple_id)
            VALUES (?, ?)
            `,
            [userId, templeId]
        );

        res.json({
            success: true
        });

    } catch(err) {

        res.status(500).json({
            error: err.message
        });

    }

});
app.post("/favourites/remove", async (req, res) => {

    const { userId, templeId } = req.body;

    try {

        await db.execute(
            `
            DELETE FROM favourite_temples
            WHERE user_id = ?
            AND temple_id = ?
            `,
            [userId, templeId]
        );

        res.json({
            success: true
        });

    } catch(err) {

        res.status(500).json({
            error: err.message
        });

    }

});
app.get("/favourites/:userId", async (req, res) => {

    try {

        const [rows] = await db.execute(
            `
            SELECT temple_id
            FROM favourite_temples
            WHERE user_id = ?
            `,
            [req.params.userId]
        );

        res.json(rows);

    } catch(err) {

        res.status(500).json({
            error: err.message
        });

    }

});

/* ------------------ LOGIN ------------------ */

app.post("/login", async (req, res) => {

    try {

        const {
            email,
            password
        } = req.body;

        const [rows] = await db.query(
            "SELECT * FROM users WHERE email = ?",
            [email]
        );

        if (rows.length === 0) {

            return res.json({
                success: false,
                message: "User not found"
            });
        }

        const user = rows[0];

        const valid =
            await bcrypt.compare(
                password,
                user.password
            );

        if (!valid) {

            return res.json({
                success: false,
                message: "Incorrect password"
            });
        }

        const religions = [];

        if (user.Hinduism) religions.push("Hinduism");
        if (user.Buddhism) religions.push("Buddhism");
        if (user.Christianity) religions.push("Christianity");
        if (user.Islam) religions.push("Islam");
        if (user.Judaism) religions.push("Judaism");
        if (user.Other) religions.push("Other");

        res.json({
            success: true,
            message: "Login successful",
            userId: user.id,
            name: user.name,
            religions: religions
        });

    } catch (err) {

        console.error(err);

        res.json({
            success: false,
            message: "Server error"
        });
    }
});

/* ------------------ HOME ------------------ */

app.get("/", (req, res) => {
    res.sendFile(__dirname + "/index.html");
});

/* ------------------ START SERVER ------------------ */

initializeDatabase()
.then(() => {

    app.get("/temples", async (req, res) => {

    try {

        const religion = req.query.religion;

        let query = "SELECT * FROM temples";
        let params = [];

        if (religion) {
            query += " WHERE religion = ?";
            params.push(religion);
        }

        const [rows] = await db.query(
            query,
            params
        );

        res.json(rows);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });
    }
});
app.get("/featured-temples", async (req, res) => {

    try {

        const [rows] = await db.query(
            "SELECT * FROM temples WHERE featured = TRUE"
        );

        res.json(rows);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });
    }
});

    app.listen(3000, () => {

        console.log(
            "Server running at http://localhost:3000"
        );

    });

})
.catch(err => {

    console.error(
        "Database initialization failed:",
        err
    );

});