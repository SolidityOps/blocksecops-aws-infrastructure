# Vault Backup Scaling Documentation

## Multi-Replica Backup Strategy

The backup CronJob is designed to handle multiple Vault replicas with a **best-effort approach**.

### Current Configuration
- **Replicas:** 2 (vault-0, vault-1)
- **Strategy:** Backup from all available replicas
- **Failure Handling:** Success if ANY replica backup succeeds

### Scaling Considerations

#### When Scaling Up (Adding Replicas)
1. **Update backup-cronjob.yaml:**
   - Increase `TOTAL_REPLICAS` variable
   - Add new volume mounts for additional PVCs
   - Add new volumes for additional StatefulSet PVCs

2. **Example for 3 replicas:**
   ```yaml
   # Add to volumeMounts:
   - name: vault-data-2
     mountPath: /vault-data-2
     readOnly: true

   # Add to volumes:
   - name: vault-data-2
     persistentVolumeClaim:
       claimName: vault-data-vault-2
   ```

3. **Update TOTAL_REPLICAS:**
   ```bash
   TOTAL_REPLICAS=3  # Update this value
   ```

#### When Scaling Down (Removing Replicas)
1. **Update backup-cronjob.yaml:**
   - Decrease `TOTAL_REPLICAS` variable
   - Remove volume mounts for removed PVCs
   - Remove volumes for removed StatefulSet PVCs

2. **Clean up old PVCs manually** (StatefulSet doesn't auto-delete them)

### Backup Behavior

#### Success Scenarios
- ✅ **All replicas available:** Backs up from all replicas
- ✅ **Some replicas down:** Backs up from available replicas
- ✅ **Only one replica available:** Backs up from that replica

#### Failure Scenarios
- ❌ **All replicas down:** Backup fails with exit code 1
- ❌ **All PVCs empty:** Backup fails (likely initialization issue)

### File Storage Considerations

**Important:** With file storage backend, all replicas contain the **same data**. The multi-replica backup provides:
- **Redundancy:** Protection against single PVC corruption
- **Availability:** Backup works even if some replicas are down
- **Validation:** Can compare data across replicas for consistency

### Alternative Approaches

For larger scale deployments, consider:

1. **Dynamic PVC Discovery:**
   - Use kubectl to discover available PVCs
   - Requires additional RBAC permissions

2. **Integrated Storage (Raft):**
   - Switch to integrated storage backend
   - Use `vault operator raft snapshot save`
   - Requires Vault Enterprise or recent Community features

3. **External Backup Tools:**
   - Use Velero for PVC backups
   - Use storage-level snapshots (EBS snapshots)

### Monitoring

Monitor backup jobs with:
- **Job Success/Failure:** Check CronJob status
- **Backup Size:** Monitor backup file sizes for consistency
- **Replica Coverage:** Check logs for which replicas were backed up

### Recovery

To restore from backup:
1. **Stop Vault StatefulSet**
2. **Clear PVC data** (if necessary)
3. **Extract backup** to PVC mount points
4. **Start Vault StatefulSet**
5. **Unseal Vault** with existing keys