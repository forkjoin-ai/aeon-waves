package main

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	r.Use(gin.Logger())

	r.GET("/users", getUsers)
	r.GET("/users/:id", getUser)
	r.POST("/users", createUser)
	r.DELETE("/users/:id", deleteUser)

	r.Run(":8080")
}

func getUsers(c *gin.Context) {
	c.JSON(http.StatusOK, []map[string]interface{}{
		{"id": 1, "name": "Alice"},
		{"id": 2, "name": "Bob"},
	})
}

func getUser(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, map[string]interface{}{
		"id": id, "name": "Alice",
	})
}

func createUser(c *gin.Context) {
	c.JSON(http.StatusCreated, map[string]interface{}{
		"id": 3,
	})
}

func deleteUser(c *gin.Context) {
	c.Status(http.StatusNoContent)
}
