(async () => {
  // Implementation for deleting conversations
  try {
    await fetch("http://localhost:3000/delete-all-convo", {
      method: "DELETE",
    });
    console.log("All conversations deleted successfully");
  } catch (error) {
    console.error("Failed to delete conversations:", error);
  }
})();
