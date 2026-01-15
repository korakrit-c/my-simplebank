package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// healthz is used by Kubernetes liveness & readiness probes
func (server *Server) healthz(ctx *gin.Context) {
	ctx.JSON(http.StatusOK, gin.H{
		"status": "ok",
	})
}
