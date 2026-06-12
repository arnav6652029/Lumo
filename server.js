const express = require("express");
const { Pool } = require("pg");
const bcrypt = require("bcrypt");

const app = express();

app.use(express.json());
app.use(express.static(__dirname));

const db = new Pool({

    connectionString:
        process.env.DATABASE_URL,

    ssl: {
        rejectUnauthorized: false
    }

});

db.query("SELECT NOW()")
.then(() => console.log("PostgreSQL Connected"))
.catch(err => console.error(err));
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

        const existingResult = await db.query(
            "SELECT * FROM users WHERE email = $1",
            [email]
        );

        const existing = existingResult.rows;
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
            "Hinduism",
            "Buddhism",
            "Christianity",
            "Islam",
            "Judaism",
            "Other"

        )

        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,

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

        await db.query(
            `
            INSERT INTO favourite_temples
            (user_id, temple_id)
            VALUES ($1,$2)
            ON CONFLICT (user_id, temple_id)
            DO NOTHING
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

        await db.query(
            `
            DELETE FROM favourite_temples
            WHERE user_id = $1
            AND temple_id = $2
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

        const result = await db.query(
            `
            SELECT temple_id
            FROM favourite_temples
            WHERE user_id = $1
            `,
            [req.params.userId]
        );

        res.json(result.rows);

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

        const result = await db.query(
            "SELECT * FROM users WHERE email = $1",
            [email]
        );

        const rows = result.rows;

        if (rows.length === 0) {

            return res.json({
                success: false,
                message: "User not found"
            });
        }

        const user = rows[0];
        console.log("USER FOUND:");
        console.log(user);

        const valid =
            await bcrypt.compare(
                password,
                user.password
            );
        console.log("Entered Password:", password);
        console.log("Stored Hash:", user.password);
        console.log("Password Valid:", valid);

        if (!valid) {

            return res.json({
                success: false,
                message: "Incorrect password"
            });
        }

        const religions = [];

        if (user.hinduism) religions.push("Hinduism");
        if (user.buddhism) religions.push("Buddhism");
        if (user.christianity) religions.push("Christianity");
        if (user.islam) religions.push("Islam");
        if (user.judaism) religions.push("Judaism");
        if (user.other) religions.push("Other");

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
const PORT = process.env.PORT || 3000;
app.post(
  "/update-religions",
  async (req, res) => {

    try {

      const {
        userId,
        religions
      } = req.body;

      await db.query(
        `
        UPDATE users
        SET
        hinduism = $1,
        buddhism = $2,
        christianity = $3,
        islam = $4,
        judaism = $5,
        other = $6
        WHERE id = $7
        `,
        [
          religions.includes(
            "Hinduism"
          ),

          religions.includes(
            "Buddhism"
          ),

          religions.includes(
            "Christianity"
          ),

          religions.includes(
            "Islam"
          ),

          religions.includes(
            "Judaism"
          ),

          religions.includes(
            "Other"
          ),

          userId
        ]
      );

      res.json({
        success: true
      });

    } catch (err) {

      console.error(err);

      res.status(500).json({
        success: false
      });
    }
  }
);
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
app.get("/temples", async (req, res) => {

    try {

        const religion = req.query.religion;

        let result;

        if (religion) {

            result = await db.query(
                "SELECT * FROM temples WHERE religion = $1",
                [religion]
            );

        } else {

            result = await db.query(
                "SELECT * FROM temples"
            );

        }

        res.json(result.rows);

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

        const result = await db.query(
            "SELECT * FROM temples WHERE featured = true"
        );

        res.json(result.rows);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: "Server Error"
        });

    }

});