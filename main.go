package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/robfig/cron/v3"
	_ "modernc.org/sqlite"
)

const defaultDBPath = "/usr/local/s-ui/db/s-ui.db"
const defaultCronSchedule = "0 0 1 * *" // 每月 1 号 00:00
const resetLogPath = "/usr/local/s-ui/logs/reset-traffic.log"

// logReset 记录重置日志
func logReset(resetType string, rowsAffected int64, err error) {
	// 确保日志目录存在
	logDir := "/usr/local/s-ui/logs"
	if mkdirErr := os.MkdirAll(logDir, 0755); mkdirErr != nil {
		log.Printf("ERROR: Failed to create log directory %s: %v", logDir, mkdirErr)
		return
	}

	logFile, fileErr := os.OpenFile(resetLogPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if fileErr != nil {
		log.Printf("ERROR: Failed to open log file %s: %v", resetLogPath, fileErr)
		return
	}
	defer logFile.Close()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	var status string
	if err != nil {
		status = fmt.Sprintf("失败 - %v", err)
	} else {
		status = fmt.Sprintf("成功 - 影响 %d 条记录", rowsAffected)
	}

	logLine := fmt.Sprintf("[%s] 重置方式: %s, 状态: %s\n", timestamp, resetType, status)
	if _, writeErr := logFile.WriteString(logLine); writeErr != nil {
		log.Printf("ERROR: Failed to write to log file %s: %v", resetLogPath, writeErr)
		return
	}

	// 确认日志写入成功
	log.Printf("Log written successfully to %s", resetLogPath)
}

// resetTrafficDB 执行实际的数据库更新操作
func resetTrafficDB() (int64, error) {
	dbPath := os.Getenv("SUI_DB_PATH")
	if dbPath == "" {
		dbPath = defaultDBPath
	}

	// 检查数据库文件是否存在
	if _, err := os.Stat(dbPath); os.IsNotExist(err) {
		return 0, fmt.Errorf("database file not found: %s", dbPath)
	}

	// 打开数据库
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return 0, fmt.Errorf("error opening database: %v", err)
	}
	defer db.Close()

	// 设置 SQLite 内部的忙等待超时（双重保险）
	_, _ = db.Exec("PRAGMA busy_timeout = 5000;")

	var lastErr error
	// 重试 5 次
	for i := 1; i <= 5; i++ {
		// 执行更新操作
		query := "UPDATE clients SET up = 0, down = 0"
		result, err := db.Exec(query)
		if err == nil {
			return result.RowsAffected()
		}

		lastErr = err
		log.Printf("[DB] Attempt %d failed: %v. Retrying in 5 seconds...", i, err)

		if i < 5 {
			time.Sleep(5 * time.Second)
		}
	}

	return 0, fmt.Errorf("error executing update after 5 attempts: %v", lastErr)
}

// resetTrafficHandler 处理手动触发的 HTTP 请求
func resetTrafficHandler(w http.ResponseWriter, r *http.Request) {
	rowsAffected, err := resetTrafficDB()
	if err != nil {
		log.Printf("[HTTP] Reset failed: %v", err)
		logReset("手动", 0, err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Printf("[HTTP] Successfully reset traffic for %d clients", rowsAffected)
	logReset("手动", rowsAffected, nil)
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status": "success", "message": "Traffic reset successfully", "rows_affected": %d}`, rowsAffected)
}

func main() {
	// 1. 设置定时任务 (东八区)
	shanghai, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		log.Printf("Warning: Could not load Asia/Shanghai, defaulting to UTC+8 offset. Error: %v", err)
		shanghai = time.FixedZone("CST", 8*3600)
	}

	// 使用 Location 创建 cron 实例
	c := cron.New(cron.WithLocation(shanghai))

	// 获取 cron 表达式配置
	cronSchedule := os.Getenv("CRON_SCHEDULE")
	if cronSchedule == "" {
		cronSchedule = defaultCronSchedule
		log.Printf("CRON_SCHEDULE not set, using default: %s", cronSchedule)
	} else {
		log.Printf("Using custom CRON_SCHEDULE: %s", cronSchedule)
	}

	// 添加定时任务
	// 表达式格式: 分 时 日 月 周
	_, err = c.AddFunc(cronSchedule, func() {
		log.Printf("[Cron] Starting scheduled traffic reset...")
		rows, err := resetTrafficDB()
		if err != nil {
			log.Printf("[Cron] Error during scheduled reset: %v", err)
			logReset("自动", 0, err)
		} else {
			log.Printf("[Cron] Scheduled reset completed. Affected rows: %d", rows)
			logReset("自动", rows, nil)
		}
	})
	if err != nil {
		log.Fatalf("Error adding cron job (schedule: %s): %v", cronSchedule, err)
	}

	c.Start()
	log.Printf("Cron job started (Asia/Shanghai). Schedule: %s", cronSchedule)

	// 2. 注册 HTTP 接口（供手动触发或状态查询）
	http.HandleFunc("/api/traffic/reset", resetTrafficHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "52893"
	}

	log.Printf("Server starting on 127.0.0.1:%s...", port)
	log.Printf("Manual reset endpoint: http://127.0.0.1:%s/api/traffic/reset", port)

	if err = http.ListenAndServe("127.0.0.1:"+port, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
